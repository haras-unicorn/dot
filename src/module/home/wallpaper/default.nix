{ self, pkgs, ... }:

# TODO: somehow check if it was ever ran and run it for the first time

let
  wallpaper = pkgs.writeShellApplication {
    name = "wallpaper";
    runtimeInputs = [ pkgs.swww ];
    text = ''
      if [[ "''${1-x}" == "x" ]]; then
        image="$(find "${self}/assets/wallpapers" -type f | shuf -n 1)"
      else
        image="$1"
      fi
      swww img "$image" || true
      lulezojne plop "$image" || true
    '';
  };
in
{
  # TODO: systemd
  wayland.windowManager.hyprland.extraConfig = ''
    exec-once = ${pkgs.swww}/bin/swww init
  '';

  home.packages = with pkgs; [
    swww
    wallpaper
  ];

  programs.lulezojne.enable = true;
}
