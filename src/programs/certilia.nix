{ inputs, ... }:

{
  flake.homeModules.programs-certilia =
    { pkgs, ... }:
    {
      home.packages = [ inputs.certilia-overlay.packages.${pkgs.stdenv.hostPlatform.system}.default ];
    };
}
