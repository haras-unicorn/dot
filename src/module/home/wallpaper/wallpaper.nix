{ self, pkgs, ... }:

{
  home.packages = with pkgs; [
    swww
  ];

  programs.lulezojne.enable = true;

  wayland.windowManager.hyprland.extraConfig = ''
    exec-once = ${pkgs.swww}/bin/swww init
    exec = ${pkgs.writeShellApplication {
      name = "swww-lulezojne";
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
