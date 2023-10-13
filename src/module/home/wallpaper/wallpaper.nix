{ self, pkgs, ... }:

{
  programs.lulezojne.enable = true;

  home.packages = with pkgs; [
    swww
  ];

  wayland.windowManager.hyprland.extraConfig = ''
    exec-once = ${pkgs.swww}/bin/swww init
    exec = ${pkgs.writeShellApplication {
      name = "wallpaper";
      runtimeInputs = [ pkgs.swww ];
      text = ''
        image="$(find "${self}/assets/wallpapers" -type f | shuf -n 1)"
        swww img "$image"
        lulezojne plop "$image"
      '';
    }}/bin/wallpaper

    misc {
      disable_hyprland_logo = true
    }
  '';
}
