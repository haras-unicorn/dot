{ pkgs, ... }:

let
  pinokio = pkgs.pinokio;
in
{
  system = {
    programs.nix-ld.enable = true;
    programs.nix-ld.libraries = with pkgs; [
      cudaPackages.cudnn
      cudaPackages.cuda_nvrtc
      cudaPackages.nccl
      cudaPackages.cuda_cudart
    ];
  };
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
