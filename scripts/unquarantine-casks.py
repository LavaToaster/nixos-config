#!/usr/bin/env python3
"""
unquarantine-casks.py

Reads the Homebrew cask list from the nix config, resolves each cask to its
installed artifacts via `brew info`, and checks Gatekeeper status.
"""

import json
import re
import subprocess
import sys
from pathlib import Path

from gatekeeper import Artifact, check_and_prompt, err, info

# ── config ───────────────────────────────────────────────────────────────────

BREW = Path("/opt/homebrew/bin/brew")
BREW_PREFIX = Path("/opt/homebrew")
CASKS_NIX = Path(__file__).resolve().parent.parent / "modules" / "darwin" / "casks.nix"


# ── parse cask names from the nix file ───────────────────────────────────────


def parse_cask_names() -> list[str]:
    """
    Extract cask names from casks.nix, handling both:
      - plain strings:    "cask-name"
      - attribute sets:   { name = "cask-name", ... }
    """
    text = CASKS_NIX.read_text()
    names = []
    for line in text.splitlines():
        stripped = line.strip()
        if stripped.startswith("#"):
            continue

        # { name = "foo" ... }
        m = re.search(r'name\s*=\s*"([^"]+)"', stripped)
        if m:
            names.append(m.group(1))
            continue

        # plain "foo"
        m = re.match(r'^"([^"]+)"', stripped)
        if m:
            names.append(m.group(1))

    return names


# ── resolve cask tokens via brew ─────────────────────────────────────────────


def find_app(name: str) -> Path | None:
    for base in [Path("/Applications"), Path.home() / "Applications"]:
        candidate = base / name
        if candidate.is_dir():
            return candidate
    return None


def find_binary(name: str) -> Path | None:
    candidate = BREW_PREFIX / "bin" / name
    if candidate.exists():
        return candidate
    return None


def resolve_casks(cask_names: list[str]) -> tuple[list[Artifact], list[str]]:
    """
    Query `brew info --cask --json=v2` and return a tuple of:
      - a list of Artifacts with resolved paths
      - a list of skipped cask descriptions
    """
    result = subprocess.run(
        [str(BREW), "info", "--cask", "--json=v2", *cask_names],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        err("Failed to query brew info. Are all casks available?")
        sys.exit(1)

    data = json.loads(result.stdout)
    artifacts: list[Artifact] = []
    skipped: list[str] = []

    for cask in data["casks"]:
        token = cask["token"]
        artifact_keys = {k for a in cask["artifacts"] for k in a if isinstance(a, dict)}

        if "pkg" in artifact_keys:
            skipped.append(f"{token} (pkg-installed)")
            continue

        for artifact in cask["artifacts"]:
            if "app" in artifact:
                for app in artifact["app"]:
                    name = (
                        app
                        if isinstance(app, str)
                        else app.get("target", app.get("app", ""))
                    )
                    if name:
                        artifacts.append(Artifact(token, name, "app", find_app(name)))
            if "binary" in artifact:
                for binary in artifact["binary"]:
                    name = (
                        binary if isinstance(binary, str) else binary.get("target", "")
                    )
                    if name:
                        artifacts.append(
                            Artifact(token, name, "binary", find_binary(name))
                        )

    return artifacts, skipped


# ── main ─────────────────────────────────────────────────────────────────────


def main() -> None:
    if not BREW.exists():
        err(f"Homebrew not found at {BREW}")
        sys.exit(1)
    if not CASKS_NIX.exists():
        err(f"Cask list not found at {CASKS_NIX}")
        sys.exit(1)

    cask_names = parse_cask_names()
    if not cask_names:
        err(f"No cask names found in {CASKS_NIX}")
        sys.exit(1)

    info(f"Found {len(cask_names)} casks in {CASKS_NIX.name}: {' '.join(cask_names)}")
    print()

    info("Querying Homebrew…")
    artifacts, skipped = resolve_casks(cask_names)

    check_and_prompt(artifacts, skipped=skipped)


if __name__ == "__main__":
    main()
