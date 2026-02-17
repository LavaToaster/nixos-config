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
      ".local/bin/bazel" = {
        source = "${pkgs.bazelisk}/bin/bazelisk";
      };
    };
    stateVersion = "23.11";
  };

  home.activation.installAzureCli = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    let
      sslCertFile = userConfig.sslCertFile or null;
      sslEnv = if sslCertFile != null then ''
        export REQUESTS_CA_BUNDLE="${sslCertFile}"
        export SSL_CERT_FILE="${sslCertFile}"
        export PIP_CERT="${sslCertFile}"
      '' else "";
      extensions = [
        "azure-devops"
      ];
      installExtensions = lib.concatMapStringsSep "\n" (ext: ''
        if ! "$HOME/.local/bin/az" extension show --name ${ext} &>/dev/null 2>&1; then
          run "$HOME/.local/bin/az" extension add --name ${ext}
        fi
      '') extensions;
    in ''
      ${sslEnv}
      if ! "$HOME/.local/bin/az" version &>/dev/null 2>&1; then
        run ${pkgs.pipx}/bin/pipx install azure-cli
      fi
      ${installExtensions}
    ''
  );

  home.activation.podmanCaCert = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    let
      sslCertFile = userConfig.sslCertFile or null;
    in lib.optionalString (sslCertFile != null) ''
      export PATH="${pkgs.openssh}/bin:$PATH"
      if ${pkgs.podman}/bin/podman machine inspect 2>/dev/null | ${pkgs.jq}/bin/jq -e '.[0].State == "running"' &>/dev/null; then
        run ${pkgs.podman}/bin/podman machine ssh -- \
          "sudo tee /etc/pki/ca-trust/source/anchors/custom-ca.pem > /dev/null" < "${sslCertFile}"
        run ${pkgs.podman}/bin/podman machine ssh -- "sudo update-ca-trust"
      fi
    ''
  );

  # Marked broken Oct 20, 2022 check later to remove this
  # https://github.com/nix-community/home-manager/issues/3344
  manual.manpages.enable = false;
}
