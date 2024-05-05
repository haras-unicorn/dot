{ pkgs, ... }:

let
  wallpaper = pkgs.writeShellApplication {
    name = "wallpaper";
    runtimeInputs = [ pkgs.swww ];
    text = ''
      image="$1"
      swww img "$image" || true
      lulezojne plop "$image" || true
    '';
  };
in
{
  shared = {
    dot = {
      desktopEnvironment.sessionStartup = [
        "${pkgs.swww}/bin/swww init"
      ];
    };
  };

  home.shared = {
    home.packages = with pkgs; [
      swww
      wallpaper
    ];

    programs.lulezojne.enable = true;
  };
}
