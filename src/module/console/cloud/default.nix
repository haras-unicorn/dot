{ pkgs, ... }:

{
  home = {
    home.packages = [
      (pkgs.azure-cli.withExtensions [ pkgs.azure-cli.extensions.ssh ])
    ];
  };
}
