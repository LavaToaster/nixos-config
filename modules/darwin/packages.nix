{ pkgs }:

with pkgs;
let
  shared-packages = import ../shared/packages.nix { inherit pkgs; };
in
shared-packages
++ [
  dockutil
  (with dotnetCorePackages; combinePackages [
    sdk_8_0
    sdk_10_0
  ])
]
++ (let p = let su = builtins.getEnv "SUDO_USER"; u = if su != "" then su else builtins.getEnv "USER"; in "/Users/" + u + "/nixos-private/darwin-packages.nix";
    in if builtins.pathExists p then import p { inherit pkgs; } else [])
