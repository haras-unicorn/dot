{ self, pkgs, ... }:

let
  swww-reload =
    pkgs.writeShellApplication {
      name = "swww-reload";
      text = ''
        ${pkgs.swww}/bin/swww img "$(find "${self}/assets/wallpapers" -type f | shuf -n 1)"
      '';
    };
in
{
  home.packages = with pkgs; [
    swww
    swww-reload
  ];

  wayland.windowManager.hyprland.extraConfig = ''
    exec-once = ${pkgs.swww}/bin/swww init
    exec = ${swww-reload}/bin/swww-reload

    misc {
      disable_hyprland_logo = true
    }
  '';
}
