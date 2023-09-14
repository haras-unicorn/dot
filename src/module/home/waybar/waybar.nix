{ hardware, pkgs, ... }:

let
  waybar-reload = pkgs.writeShellApplication {
    name = "waybar-reload";
    text = ''
      pkill waybar || true
      nohup ${pkgs.waybar}/bin/waybar >/dev/null 2>&1 &
    '';
  };
in
{
  home.packages = [
    waybar-reload
  ];

  programs.waybar.enable = true;
  programs.waybar.settings = [
    {
      output = hardware.mainMonitor;
      network = { interface = hardware.networkInterface; };
    }
    (builtins.fromJSON (builtins.readFile ./config.json))
  ];
  programs.waybar.style = builtins.readFile ./style.css;

  wayland.windowManager.hyprland.extraConfig = ''
    exec-once = ${pkgs.waybar}/bin/waybar
    exec = ${waybar-reload}/bin/waybar-reload
  '';
}
