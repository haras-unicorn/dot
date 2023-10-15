{ self, pkgs, ... }:

let
  wallpaper = pkgs.writeShellApplication {
    name = "wallpaper";
    runtimeInputs = [ pkgs.swww ];
    text = ''
      if [[ "''${1-x}" == "x" ]]; then
        image="$(find "${self}/assets/wallpapers" -type f | shuf -n 1)"
      else
        image="''${1-x}"
      fi
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

    misc {
      disable_hyprland_logo = true
    }
  '';
}
