{ pkgs, ... }:

{
  branch.homeManagerModule.homeManagerModule = {
    home.packages = [
      (pkgs.azure-cli.withExtensions [ pkgs.azure-cli.extensions.ssh ])
    ];
  };
}
