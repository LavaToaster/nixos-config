{ pkgs, config, ... }:

{
  ".config/nvim" = {
    source = ./config/nvim;
    recursive = true;
  };

}
