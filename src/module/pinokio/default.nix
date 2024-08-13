{ pkgs, ... }:

let
  pinokio = pkgs.buildFHSEnv {
    name = "pinokio";
    runScript = "pinokio";
    targetPkgs = pkgs: (with pkgs; [
      pkgs.pinokio
      cudaPackages.cudnn
      cudaPackages.cuda_nvrtc
      cudaPackages.nccl
      cudaPackages.cuda_cudart
    ]);
  };
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
