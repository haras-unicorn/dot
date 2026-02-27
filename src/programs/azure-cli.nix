{ ... }:

{
  flake.homeModules.programs-azure-cli =
    { pkgs, ... }:
    {
      home.packages = [
        (pkgs.azure-cli.withExtensions [ pkgs.azure-cli.extensions.ssh ])
      ];
    };
}
