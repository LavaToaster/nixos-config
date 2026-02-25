{
  config,
  pkgs,
  userConfig,
  ...
}:

let
  user = userConfig.username;
in

{

  imports = [
    ../../modules/darwin/home-manager.nix
    ../../modules/shared
  ];

  # Nix is managed by Determinate Nix (uses macOS Keychain for CA certs)
  nix.enable = false;

  # Turn off NIX_PATH warnings now that we're using flakes

  # Load configuration that is shared across systems
  environment.variables = {
    DOTNET_ROOT = "${pkgs.dotnet-sdk_8}/share/dotnet";
  };

  environment.systemPackages =
    with pkgs;
    (import ../../modules/shared/packages.nix { inherit pkgs; });

  system = {
    checks.verifyNixPath = false;
    primaryUser = user;
    stateVersion = 5;

    defaults = {
      NSGlobalDomain = {
        AppleShowAllExtensions = true;
        ApplePressAndHoldEnabled = false;

        # 120, 90, 60, 30, 12, 6, 2
        KeyRepeat = 2;

        # 120, 94, 68, 35, 25, 15
        InitialKeyRepeat = 35;

        "com.apple.mouse.tapBehavior" = 1;
        "com.apple.sound.beep.volume" = 0.0;
        "com.apple.sound.beep.feedback" = 0;
      };

      dock = {
        autohide = true;
        show-recents = false;
        launchanim = true;
        orientation = "bottom";
        tilesize = 48;
      };

      finder = {
        _FXShowPosixPathInTitle = false;
      };

      trackpad = {
        Clicking = true;
        TrackpadThreeFingerDrag = true;
      };

      CustomUserPreferences = {
        "com.apple.symbolichotkeys" = {
          AppleSymbolicHotKeys = {
            # Disable 'Cmd + Space' for Spotlight Search
            "64" = {
              enabled = false;
            };
            # Disable 'Cmd + Alt + Space' for Finder search window
            "65" = {
              enabled = false;
            };
          };
        };
      };
    };

    activationScripts.postActivation.text = ''
      # Following line should allow us to avoid a logout/login cycle when changing settings
      sudo -u ${user} /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u

      # Symlink podman socket to /var/run/docker.sock for Docker compatibility
      user_tmp=$(sudo -u ${user} getconf DARWIN_USER_TEMP_DIR)
      ln -sf "''${user_tmp}podman/podman-machine-default-api.sock" /var/run/docker.sock

      # Symlink nix-installed podman to /usr/local/bin so Podman Desktop can find it
      ln -sf "${pkgs.podman}/bin/podman" /usr/local/bin/podman
      ln -sf "${pkgs.podman-compose}/bin/podman-compose" /usr/local/bin/podman-compose
      ln -sf "${pkgs.kubectl}/bin/kubectl" /usr/local/bin/kubectl
      ln -sf "${pkgs.kind}/bin/kind" /usr/local/bin/kind
    '';
  };
}
