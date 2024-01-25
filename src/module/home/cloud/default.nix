{ pkgs, ... }:

# FIXME: azure extension add fails with some pip error

{
  home.packages = with pkgs; [
    azure-cli
  ];

  home.file.".azure/config".source = ./azure-config;
}
