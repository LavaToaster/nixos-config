{
  pkgs,
  lib,
  userConfig,
  ...
}:

{
  imports = [
    ./shell.nix
    ./git.nix
    ./ssh.nix
    ./tmux.nix
    ./editors.nix
    ./ghostty.nix
    ./eza.nix
    ./zoxide.nix
    ./tealdeer.nix
    ./gh.nix
    ./direnv.nix
    ./carapace.nix
    ./pay-respects.nix
  ];

  home = {
    enableNixpkgsReleaseCheck = false;
    packages = pkgs.callPackage ../modules/darwin/packages.nix { };
    file = {
      ".config/nvim" = {
        source = ../modules/shared/config/nvim;
        recursive = true;
      };
    };
    stateVersion = "23.11";
  };

  # Marked broken Oct 20, 2022 check later to remove this
  # https://github.com/nix-community/home-manager/issues/3344
  manual.manpages.enable = false;
}
