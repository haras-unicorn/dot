{ hardware, ... }:

{
  wayland.windowManager.hyprland = {
    enable = true;
    enableNvidiaPatches = true;
    xwayland.enable = true;
    extraConfig = ''
      monitor = , preferred, auto, 1
      monitor = ${hardware.mainMonitor}, highrr, auto, 1
      
      ${builtins.readFile ./hyprland.conf}
    '';
  };
}
