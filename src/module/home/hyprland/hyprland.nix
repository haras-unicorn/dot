{ hardware, config, ... }:

{
  wayland.windowManager.hyprland.enable = true;
  wayland.windowManager.hyprland.enableNvidiaPatches = true;
  wayland.windowManager.hyprland.xwayland.enable = true;
  wayland.windowManager.hyprland.extraConfig = ''
    monitor = , preferred, auto, 1
    monitor = ${hardware.mainMonitor}, highrr, auto, 1
  
    ${builtins.readFile ./hyprland.conf}

    source = ${config.xdg.configHome}/hypr/colors.conf
  '';

  programs.lulezojne.config.plop = [
    {
      template = builtins.readFile ./colors.conf;
      "in" = "${config.xdg.configHome}/hypr/colors.conf";
    }
  ];
}
