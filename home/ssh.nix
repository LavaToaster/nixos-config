{ userConfig, ... }:

let
  user = userConfig.username;
in
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    includes = [
      "/Users/${user}/.ssh/config_external"
    ];
    matchBlocks = {
      "*" = {
        sendEnv = [
          "LANG"
          "LC_*"
        ];
        hashKnownHosts = true;
      };
    };
  };
}
