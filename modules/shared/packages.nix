{ pkgs }:

with pkgs;
[
  # General packages for development and system management
  bash-completion
  bat
  btop
  coreutils
  killall
  openssh
  sqlite
  wget
  zip

  # Encryption and security tools
  gnupg

  # Container tools
  podman
  podman-compose

  # Media-related packages
  fd
  nerd-fonts.fira-code

  # Node.js development tools
  nodejs_24

  neovim
  diff-so-fancy
  difftastic

  # Text and terminal utilities
  htop
  jq
  ripgrep
  tree
  tmux
  unrar
  unzip
  zsh-powerlevel10k

  # Development tools
  gnumake
  just
  nil
  nixd
  opentofu
  kind
  kubectl
  k9s
  kubie
  awscli2
  pipx
  nvd
  bazelisk
  bazel-watcher
  lazygit
  fzf

  # Programming languages and runtimes
  go
  rustc
  cargo
  openjdk

  # Python packages
  python3
  virtualenv

  # Productivity
  obsidian
]
