{ pkgs, ... }:

# FIXME: azure ssh extension can't find oschmod

{
  home.shared = {
    home.packages = with pkgs; [
      (azure-cli.withExtensions (with pkgs; [
        azure-cli-extensions.ssh
      ]))
    ];

    home.file.".azure/config".source = ./azure-config;
  };
}
