{ self, pkgs, ... }:

let
  swww-img = pkgs.writeShellScriptBin "swww-img" ''
    ${pkgs.swww}/bin/swww img "$(find "${self}/assets/wallpapers" -type f | shuf -n 1)"
  '';
in
{
  home.packages = with pkgs; [
    swww
    swww-img
  ];

  wayland.windowManager.hyprland.extraConfig = ''
    exec-once = ${pkgs.swww}/bin/swww init
    exec = ${swww-img}/bin/swww-img

    bind = super, tab, exec, ${swww-img}/bin/swww-img
  '';
}
