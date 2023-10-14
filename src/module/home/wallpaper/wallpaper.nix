{ self, pkgs, ... }:

let
  swww-lulezojne = pkgs.writeShellApplication {
    name = "swww-lulezojne";
    runtimeInputs = [ pkgs.swww ];
    text = ''
      image="$(find "${self}/assets/wallpapers" -type f | shuf -n 1)"
      swww img "$image"
      lulezojne plop "$image"
    '';
  };
in
{
  home.packages = with pkgs; [
    swww
    swww-lulezojne
  ];

  programs.lulezojne.enable = true;

  wayland.windowManager.hyprland.extraConfig = ''
    exec-once = ${pkgs.swww}/bin/swww init
    exec = ${swww-lulezojne}/bin/swww-lulezojne

    misc {
      disable_hyprland_logo = true
    }
  '';
}
