{ hardware, pkgs, ... }:

{
  home.packages = [
    (pkgs.writeShellApplication {
      name = "waybar-reload";
      text = ''
        pkill waybar
        nohup waybar &
      '';
    })
  ];
  programs.waybar.enable = true;
  programs.waybar.settings = [
    {
      output = hardware.mainMonitor;
    }
    (builtins.fromJSON (builtins.readFile ./config.json))
  ];
  programs.waybar.style = builtins.readFile ./style.css;

  wayland.windowManager.hyprland.extraConfig = ''
    exec-once = waybar
    exec = waybar-reload
  '';
}
