#!/usr/bin/env bash
set -e

system="aarch64-darwin"

if [ ! -f "$HOME/nixos-private/user.nix" ]; then
  echo "Error: ~/nixos-private/user.nix not found."
  echo "Create it first — see README.md for details."
  exit 1
fi

echo "Building system configuration..."
NIXPKGS_ALLOW_UNFREE=1 nix --extra-experimental-features 'nix-command flakes' build --impure ".#darwinConfigurations.${system}.system"

echo "Switching to new generation..."
sudo ./result/sw/bin/darwin-rebuild switch --impure --flake ".#${system}"
unlink ./result

echo "Done. Open a new shell to pick up changes."
