{ pkgs, ... }:

# TODO: use instead of waybar after https://github.com/elkowar/eww/pull/743

let
  pkg = pkgs.eww-wayland;
  bin = "${pkg}/bin/eww";
in
{
  de.sessionStartup = [
    "${bin} daemon"
  ];

  de.keybinds = [
    {
      mods = [ "super" ];
      key = "s";
      command = "${bin} open --toggle sysinfo";
    }
  ];

  home.packages = [
    pkg
  ];

  # programs.eww.enable = true;
  # programs.eww.package = pkg;
  # programs.eww.configDir = ./config;
}
