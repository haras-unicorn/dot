{ pkgs, ... }:

{
  home = {
    shared = {
      home.packages = with pkgs; [
        pinokio
      ];

      xdg.desktopEntries = {
        pinokio = {
          name = "Pinokio";
          exec = "${pkgs.pinokio}/bin/pinokio";
          terminal = false;
        };
      };
    };
  };
}
