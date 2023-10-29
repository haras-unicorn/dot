{ pkgs, hardware, config, ... }:

let
  layout = pkgs.writeShellApplication {
    name = "layout";
    runtimeInputs = [ pkgs.hyprland ];
    text = ''
      hyprctl devices | \
        grep -Pzo "Keyboard at.*\n.*\n" | \
        grep -Pva "Keyboard at" | \
        grep -Pva "power" | \
        xargs -IR hyprctl switchxkblayout R next
    '';
  };
in
{
  home.packages = [ layout ];

  wayland.windowManager.hyprland.enable = true;
  wayland.windowManager.hyprland.enableNvidiaPatches = true;
  wayland.windowManager.hyprland.xwayland.enable = true;
  wayland.windowManager.hyprland.extraConfig = ''
    env = XDG_CURRENT_DESKTOP, Hyprland
    env = XDG_SESSION_DESKTOP, Hyprland

    monitor = , preferred, auto, 1
    monitor = ${hardware.mainMonitor}, highrr, auto, 1
  
    ${builtins.readFile ./hyprland.conf}

    source = ${config.xdg.configHome}/hypr/colors.conf

    bind = super, Space, exec, ${layout}/bin/layout
  '';

  programs.lulezojne.config.plop = [
    {
      template = builtins.readFile ./colors.conf;
      "in" = "${config.xdg.configHome}/hypr/colors.conf";
    }
  ];
}
