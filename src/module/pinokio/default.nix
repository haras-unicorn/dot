{ pkgs, ... }:

let
  pinokio = pkgs.pinokio.overrideAttrs (final: prev: {
    buildInputs = (prev.buildInputs or [ ]) ++ [
      pkgs.cudaPackages.nccl
    ];
  });
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
