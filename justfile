system := "aarch64-darwin"
flake_system := "darwinConfigurations." + system + ".system"

# Build the system configuration
build *args:
    nix build --impure .#{{flake_system}} {{args}}

# Build and switch to the new generation
switch *args: (build args)
    # See https://github.com/nix-darwin/nix-darwin/issues/1457 on why we need sudo
    sudo ./result/sw/bin/darwin-rebuild switch --impure --flake .#{{system}} {{args}}
    unlink ./result

# Garbage collect generations older than 7 days
gc:
    sudo nix-collect-garbage --delete-older-than 7d

# List generations and roll back to a selected one
rollback:
    #!/usr/bin/env bash
    set -e
    echo "Available generations:"
    /run/current-system/sw/bin/darwin-rebuild --list-generations
    read -p "Enter generation number for rollback: " GEN_NUM
    if [ -z "$GEN_NUM" ]; then
      echo "No generation number entered. Aborting."
      exit 1
    fi
    /run/current-system/sw/bin/darwin-rebuild switch --flake .#{{system}} --switch-generation "$GEN_NUM"
    echo "Rolled back to generation $GEN_NUM."

# Generate ~/nixos-private/user.nix interactively
init:
    #!/usr/bin/env bash
    set -e
    PRIVATE_DIR="$HOME/nixos-private"
    mkdir -p "$PRIVATE_DIR"
    if [[ -f "$PRIVATE_DIR/user.nix" ]]; then
      echo "user.nix already exists:"
      cat "$PRIVATE_DIR/user.nix"
      read -p "Overwrite? [y/N] " response
      if [[ ! "$response" =~ ^[Yy] ]]; then
        echo "Keeping existing user.nix."
        exit 0
      fi
    fi
    USERNAME=$(whoami)
    if command -v git >/dev/null 2>&1; then
      GIT_EMAIL=$(git config --get user.email || true)
      GIT_NAME=$(git config --get user.name || true)
    fi
    [[ -z "$GIT_EMAIL" ]] && read -p "Email: " GIT_EMAIL
    [[ -z "$GIT_NAME" ]] && read -p "Name: " GIT_NAME
    echo "Username: $USERNAME"
    echo "Email: $GIT_EMAIL"
    echo "Name: $GIT_NAME"
    read -p "Correct? [y/N] " choice
    if [[ ! "$choice" =~ ^[Yy] ]]; then
      echo "Aborted."
      exit 1
    fi
    cat > "$PRIVATE_DIR/user.nix" << EOF
    {
      username = "$USERNAME";
      name = "$GIT_NAME";
      email = "$GIT_EMAIL";
    }
    EOF
    echo "user.nix created at $PRIVATE_DIR/user.nix"
