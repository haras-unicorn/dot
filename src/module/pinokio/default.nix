{ pkgs, ... }:

let
  pinokio = (pkgs.buildFHSEnv {
    name = "pinokio";
    targetPkgs = pkgs: (with pkgs; [
      cudaPackages.nccl
      pinokio
    ]);
    runScript = "pinokio";
  }).env;
in
{
  home = {
    shared = {
      home.packages = [
        pinokio
      ];

      xdg.desktopEntries = {
        pinokio = {
          name = "Pinokio";
          exec = "${pinokio}/bin/pinokio";
          terminal = false;
        };
      };
    };
  };
}
