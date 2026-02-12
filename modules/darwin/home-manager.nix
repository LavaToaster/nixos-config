{
  config,
  pkgs,
  lib,
  home-manager,
  userConfig,
  ...
}:

let
  user = userConfig.username;
in
{
  imports = [
    ./dock
  ];

  # It me
  users.users.${user} = {
    name = "${user}";
    home = "/Users/${user}";
    isHidden = false;
    shell = pkgs.zsh;
  };

  homebrew = {
    enable = true;
    casks = pkgs.callPackage ./casks.nix { };
    # onActivation.cleanup = "uninstall";
    onActivation.autoUpdate = true;
    onActivation.upgrade = true;

    # These app IDs are from using the mas CLI app
    # mas = mac app store
    # https://github.com/mas-cli/mas
    #
    # $ nix shell nixpkgs#mas
    # $ mas search <app name>
    #
    # If you have previously added these apps to your Mac App Store profile (but not installed them on this system),
    # you may receive an error message "Redownload Unavailable with This Apple ID".
    # This message is safe to ignore. (https://github.com/dustinlyons/nixos-config/issues/83)

    masApps = {
      # "wireguard" = 1451685025;
    };
  };

  # Enable home-manager
  home-manager = {
    useGlobalPkgs = true;
    backupFileExtension = ".bak";
    extraSpecialArgs = { inherit userConfig; };
    users.${user} = import ../../home;
  };

  # Fully declarative dock using the latest from Nix Store
  local = {
    dock = {
      enable = true;
      username = user;
      entries = [
        { path = "/Applications/Zen.app/"; }
        { path = "/Applications/Zed.app/"; }
        { path = "/Applications/Ghostty.app/"; }
        { path = "/Applications/Microsoft Teams.app/"; }
        { path = "/Applications/Microsoft Outlook.app/"; }
        { path = "/System/Applications/Music.app/"; }
        {
          path = "${config.users.users.${user}.home}/Downloads/";
          section = "others";
          options = "--sort name --view fan --display stack";
        }
      ];
    };
  };
}
