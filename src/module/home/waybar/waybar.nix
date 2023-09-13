{ hardware, ... }:

{
  programs.waybar.enable = true;
  programs.waybar.settings = {
    mainBar = {
      layer = "top";
      position = "top";
      height = 30;
      output = [ hardware.mainMonitor ];
      modules-left = [ "sway/mode" "sway/workspaces" "wlr/taskbar" ];
      modules-right = [ "tray" ];
      "sway/workspaces" = {
        disable-scroll = true;
        all-outputs = true;
      };
    };
  };

  wayland.windowManager.hyprland.extraConfig = ''
    monitor = ${hardware.mainMonitor}, addreserved, 32, 0, 0, 0, 0
  '';
}
