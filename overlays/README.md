# Overlays

Nix overlays let you override or extend packages from nixpkgs. Drop a `.nix` file in this directory and it gets picked up automatically on the next build.

Use cases:
- Pin a package to a specific version
- Patch a broken package
- Pull a package from a fork or different branch
- Add a custom package that doesn't exist in nixpkgs

Each file should export a function `final: prev: { ... }` where `prev` is the original package set and `final` is the result after all overlays are applied.

Example (`overlays/my-override.nix`):
```nix
final: prev: {
  my-package = prev.my-package.overrideAttrs (old: {
    version = "1.2.3";
    src = prev.fetchFromGitHub { ... };
  });
}
```
