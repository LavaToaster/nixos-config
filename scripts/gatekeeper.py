"""
gatekeeper.py

Shared utilities for checking macOS Gatekeeper status and interactively
unquarantining apps and binaries.
"""

import subprocess
import sys
from dataclasses import dataclass, field
from pathlib import Path

# ── colours ──────────────────────────────────────────────────────────────────

RED = "\033[0;31m"
GREEN = "\033[0;32m"
YELLOW = "\033[1;33m"
CYAN = "\033[0;36m"
BOLD = "\033[1m"
RESET = "\033[0m"

INDENT = "          "


def info(msg: str) -> None:
    print(f"{CYAN}[info]{RESET}  {msg}")


def warn(msg: str) -> None:
    print(f"{YELLOW}[warn]{RESET}  {msg}")


def ok(msg: str) -> None:
    print(f"{GREEN}[ok]{RESET}    {msg}")


def err(msg: str) -> None:
    print(f"{RED}[err]{RESET}   {msg}", file=sys.stderr)


# ── artifact ─────────────────────────────────────────────────────────────────


@dataclass
class Artifact:
    group: str  # cask name, or custom group name
    name: str  # display name (e.g. "Ghostty.app", "claude")
    kind: str  # "app" or "binary"
    path: Path | None  # resolved path on disk, None if not found


# ── gatekeeper / quarantine checks ───────────────────────────────────────────


def _has_quarantine_xattr(path: Path) -> bool:
    """Check if the quarantine extended attribute is present."""
    result = subprocess.run(
        ["xattr", "-p", "com.apple.quarantine", str(path)],
        capture_output=True,
    )
    return result.returncode == 0


def _is_quarantine_blocked(path: Path) -> bool:
    """Check if the quarantine xattr flags indicate the app is blocked.

    The quarantine value is a semicolon-separated string whose first field
    is a hex flag word.  Two bits matter here:
      - 0x0040  QTN_FLAG_USER_APPROVED – set after the user approves the
                app on first launch (see https://eclecticlight.co/2020/10/29/quarantine-and-the-quarantine-flag/).
      - 0x0200  Observed on apps that macOS considers unapproved; not
                publicly named in Apple headers.
    An app is blocked when 0x0200 is set but 0x0040 is not.
    """
    result = subprocess.run(
        ["xattr", "-p", "com.apple.quarantine", str(path)],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        return False
    flags_str = result.stdout.strip().split(";")[0]
    try:
        flags = int(flags_str, 16)
    except ValueError:
        return False
    return bool(flags & 0x0200) and not bool(flags & 0x0040)


def _is_binary(path: Path) -> bool:
    """Check if a file is a compiled binary (vs a shell script or other text).
    Checks for Mach-O format, OH YEAH."""
    result = subprocess.run(["file", str(path)], capture_output=True, text=True)
    return "Mach-O" in result.stdout


def _resolves_into_app_bundle(path: Path) -> bool:
    """Check if a binary's real path lives inside a .app bundle."""
    real = path.resolve()
    return any(p.suffix == ".app" for p in real.parents)


def is_rejected(artifact: Artifact) -> bool:
    """Check if an artifact will be blocked by macOS.

    For apps: quarantine flag 0x0200 set, OR (fail spctl AND have quarantine xattr).
    For binaries: must be a real Mach-O, not inside an .app, and have quarantine xattr.
    """
    if artifact.path is None:
        return False

    path = artifact.path

    print(f" Name: {path.name}, Kind: {artifact.kind}")

    if artifact.kind == "app":
        if _is_quarantine_blocked(path):
            return True
        result = subprocess.run(
            ["spctl", "--assess", "--type", "execute", str(path)],
            capture_output=True,
        )
        if result.returncode == 0:
            return False
        return _has_quarantine_xattr(path)
    else:
        if not _is_binary(path):
            return False
        if _resolves_into_app_bundle(path):
            return False
        return _has_quarantine_xattr(path)


def unquarantine(path: Path) -> bool:
    """Remove the quarantine extended attribute from a path."""
    result = subprocess.run(["sudo", "xattr", "-dr", "com.apple.quarantine", str(path)])
    return result.returncode == 0


# ── classify and prompt ──────────────────────────────────────────────────────


@dataclass
class GroupResult:
    clean: list[tuple[Artifact, Path]] = field(default_factory=list)
    rejected: list[tuple[Artifact, Path]] = field(default_factory=list)
    not_found: list[str] = field(default_factory=list)


def classify(artifacts: list[Artifact]) -> dict[str, GroupResult]:
    """Classify a list of artifacts into per-group results."""
    results: dict[str, GroupResult] = {}

    for artifact in artifacts:
        if artifact.group not in results:
            results[artifact.group] = GroupResult()
        result = results[artifact.group]

        if artifact.path is None:
            result.not_found.append(artifact.name)
        elif is_rejected(artifact):
            result.rejected.append((artifact, artifact.path))
        else:
            result.clean.append((artifact, artifact.path))

    return results


def check_and_prompt(
    artifacts: list[Artifact],
    skipped: list[str] | None = None,
) -> None:
    """Classify artifacts, display grouped results, and prompt to unquarantine."""
    results = classify(artifacts)

    print()

    if skipped:
        info(f"{len(skipped)} cask(s) skipped:")
        for entry in skipped:
            print(f"{INDENT}- {entry}")
        print()

    for group, result in results.items():
        if result.rejected:
            print(f"{YELLOW}[??]{RESET}    {BOLD}{group}{RESET}")
        else:
            ok(f"{BOLD}{group}{RESET}")

        for artifact, path in result.clean:
            print(f"{INDENT}✓ {path.name} ({artifact.kind})")
        for artifact, path in result.rejected:
            print(f"{INDENT}✗ {path.name} ({artifact.kind})")
        for name in result.not_found:
            print(f"{INDENT}? {name} (not found)")

        if result.rejected:
            rejected_labels = [f"{path.name} ({a.kind})" for a, path in result.rejected]
            yn = (
                input(f"{INDENT}Unquarantine {', '.join(rejected_labels)}? [y/N]: ")
                .strip()
                .lower()
            )
            if yn == "y":
                for artifact, path in result.rejected:
                    if unquarantine(path):
                        ok(f"Unquarantined {path.name}")
                    else:
                        err(f"Failed to unquarantine {path.name}")
            else:
                warn(f"Skipped {group}")

    print()
    ok("Done! 🎉")
