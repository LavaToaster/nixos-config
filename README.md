# nixos-config

This is my personal NixOS configuration for an ARM MacOS device.

## Prerequisites

Install [Determinate Nix](https://docs.determinate.systems/) using the macOS `.pkg` installer.

## First-time setup

1. Create `~/nixos-private/user.nix` with your details:

```nix
{
  username = "your-username";
  name = "Your Name";
  email = "your@email.com";
}
```

2. Bootstrap the system:

```sh
./bootstrap.sh
```

3. Open a new shell. `just` is now available.

### Private configuration

Nix flakes can only see files tracked by Git, so personal and machine-specific configuration lives in `~/nixos-private/` — outside this repository — to keep it out of the public repo. The flake reads from this directory at build time using `--impure`.

```
~/nixos-private/
  user.nix                      # required — username, name, email
  darwin-packages.nix            # optional — extra darwin packages
  shell.nix                      # optional — extra shell config
  overlays/                      # optional — extra nixpkgs overlays
```

## Day-to-day usage

```sh
just switch    # build and activate (aliased to `rb`)
just build     # build only, no switch
just gc        # garbage collect generations older than 7 days
just rollback  # list generations and roll back to one
```

## Structure

```
flake.nix                  # single aarch64-darwin configuration
justfile                   # build/switch/gc/rollback recipes
home/                      # home-manager modules (shell, git, ssh, tmux, editors)
hosts/darwin/              # top-level darwin system config
modules/darwin/            # darwin-specific modules (packages, casks, dock, files)
modules/shared/            # nixpkgs config, packages
overlays/                  # nixpkgs overlays (auto-loaded)
scripts/                   # helper scripts (gatekeeper, unquarantine)
```
