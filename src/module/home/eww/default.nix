{ pkgs, ... }:

# TODO: use instead of waybar after https://github.com/elkowar/eww/pull/743

let
  pkg = pkgs.eww-wayland;
in
{
  de.sessionStartup = [
    "${pkg}/bin/eww daemon"
  ];

  de.keybinds = [
    {
      mods = [ "super" ];
      key = "s";
      command = "${pkg}/bin/eww open top-bar";
    }
  ];

  programs.eww.enable = true;
  programs.eww.package = pkg;
  programs.eww.configDir = ./config;
}
