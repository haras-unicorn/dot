{ self, pkgs, ... }:

let
  wallpaper = pkgs.writeShellApplication {
    name = "wallpaper";
    runtimeInputs = [ pkgs.swww ];
    text = ''
      image="$(find "${self}/assets/wallpapers" -type f | shuf -n 1)"
      swww img "$image" || true
      lulezojne plop "$image" || true
    '';
  };
in
{
  home.packages = with pkgs; [
    swww
    wallpaper
  ];

  programs.lulezojne.enable = true;

  wayland.windowManager.hyprland.extraConfig = ''
    exec-once = ${pkgs.swww}/bin/swww init
    exec = ${wallpaper}/bin/wallpaper

    misc {
      disable_hyprland_logo = true
    }
  '';
}
