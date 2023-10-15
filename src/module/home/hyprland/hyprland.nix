{ hardware, ... }:

{
  wayland.windowManager.hyprland.enable = true;
  wayland.windowManager.hyprland.enableNvidiaPatches = true;
  wayland.windowManager.hyprland.xwayland.enable = true;
  wayland.windowManager.hyprland.extraConfig = ''
    monitor = , preferred, auto, 1
    monitor = ${hardware.mainMonitor}, highrr, auto, 1
  
    ${builtins.readFile ./hyprland.conf}
  '';
}
