# nixos-config

Nix flake-based system configuration, currently targeting macOS (nix-darwin). Structure supports adding other OS targets later without refactoring.

## Nix Flakes and Git

Nix flakes only see git-tracked files. New files must be `git add`ed (at least staged) before they are visible to builds.

## Build

Uses `just` (see `justfile`):

- `just switch` - build and apply the configuration
- `just build` - build without switching
- `just gc` - garbage collect old generations
- `just rollback` - list and roll back to a previous generation
- `just init` - generate user.nix with git identity

## Project Structure

- `modules/shared/config/nvim/` - Neovim config (kickstart.nvim-based, lazy.nvim)
  - `lua/plugins/` - Plugin files, auto-imported by lazy.nvim
- `modules/shared/packages.nix` - Shared packages
- `modules/shared/files.nix` - Files copied to `~/.config/` via home-manager
- `modules/shared/home-manager.nix` - Home-manager config
- `home/` - Home-manager modules (tmux, shell, etc.)

## Neovim

- LSP servers installed via Mason (not Nix) for faster iteration
- LSP configured via native `vim.lsp.config` / `vim.lsp.enable` (Neovim 0.11+)
- Treesitter uses the `main` branch API
