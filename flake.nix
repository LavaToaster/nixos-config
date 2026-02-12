{
  description = "macOS configuration";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew = {
      url = "github:zhaofengli-wip/nix-homebrew";
    };
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
  };
  outputs =
    {
      self,
      darwin,
      nix-homebrew,
      homebrew-bundle,
      homebrew-core,
      homebrew-cask,
      home-manager,
      nixpkgs,
    }@inputs:
    let
      system = "aarch64-darwin";
      # SUDO_USER is set by sudo to the invoking user; fall back to USER for non-sudo builds
      actualUser = let su = builtins.getEnv "SUDO_USER"; in if su != "" then su else builtins.getEnv "USER";
      privatePath = "/Users/" + actualUser + "/nixos-private";
      userConfig = import (privatePath + "/user.nix");
      user = userConfig.username;
    in
    {
      darwinConfigurations.${system} = darwin.lib.darwinSystem {
        specialArgs = inputs // {
          inherit userConfig;
        };
        modules = [
          { nixpkgs.hostPlatform = system; }
          home-manager.darwinModules.home-manager
          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              inherit user;
              enable = true;
              taps = {
                "homebrew/homebrew-core" = homebrew-core;
                "homebrew/homebrew-cask" = homebrew-cask;
                "homebrew/homebrew-bundle" = homebrew-bundle;
              };
              mutableTaps = false;
              autoMigrate = true;
            };
          }
          ./hosts/darwin
        ];
      };
    };
}
