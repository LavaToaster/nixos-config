{ config, pkgs, ... }:

{

  nixpkgs = {
    config = {
      allowUnfree = true;
      allowBroken = true;
      allowInsecure = false;
      allowUnsupportedSystem = true;
    };

    overlays =
      # Apply each overlay found in the /overlays directory
      let path = ../../overlays; in with builtins;
      map (n: import (path + ("/" + n)))
          (filter (n: match ".*\\.nix" n != null ||
                      pathExists (path + ("/" + n + "/default.nix")))
                  (attrNames (readDir path)))
      # Conditionally load work overlays
      ++ (let workPath = let su = builtins.getEnv "SUDO_USER"; u = if su != "" then su else builtins.getEnv "USER"; in "/Users/" + u + "/nixos-private/overlays"; in
          if builtins.pathExists workPath then
            builtins.map (n: import (workPath + ("/" + n)))
              (builtins.filter (n: builtins.match ".*\\.nix" n != null)
                (builtins.attrNames (builtins.readDir workPath)))
          else []);
  };
}
