{ hardware, pkgs, ... }:

let
  waybar-reload = pkgs.writeShellApplication {
    name = "waybar-reload";
    runtimeInputs = [ pkgs.coreutils-full pkgs.waybar ];
    text = ''
      pkill -x waybar || true
      waybar >/dev/null 2>&1 & disown
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
