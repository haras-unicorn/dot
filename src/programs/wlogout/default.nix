{
  pkgs,
  lib,
  config,
  ...
}:

let
  colors = config.lib.stylix.colors.withHashtag;

  hasMonitor = config.dot.hardware.monitor.enable;
  hasWayland = config.dot.hardware.graphics.wayland;
  hasMouse = config.dot.hardware.mouse.enable;
in
{
  homeManagerModule = lib.mkIf (hasMonitor && hasMouse && hasWayland) {
    dot.desktopEnvironment.logout = "${pkgs.wlogout}/bin/wlogout -p layer-shell";

    programs.wlogout.enable = true;
    programs.wlogout.layout = [
      {
        label = "lock";
        action = "${pkgs.systemd}/bin/loginctl lock-session";
        text = "Lock";
        keybind = "l";
      }
      {
        label = "logout";
        action = "${pkgs.systemd}/bin/loginctl terminate-user $USER";
        text = "Logout";
        keybind = "e";
      }
      {
        label = "suspend";
        action = "${pkgs.systemd}/bin/systemctl suspend-then-hibernate";
        text = "Suspend";
        keybind = "u";
      }
      {
        label = "hibernate";
        action = "${pkgs.systemd}/bin/systemctl hibernate";
        text = "Hibernate";
        keybind = "h";
      }
      {
        label = "reboot";
        action = "${pkgs.systemd}/bin/systemctl reboot";
        text = "Reboot";
        keybind = "r";
      }
      {
        label = "shutdown";
        action = "${pkgs.systemd}/bin/systemctl poweroff";
        text = "Shutdown";
        keybind = "s";
      }
    ];

    programs.wlogout.style = ''
      * {
        font-family: '${config.stylix.fonts.sansSerif.name}';
        font-size: ${builtins.toString config.stylix.fonts.sizes.desktop}pt;
      }

      #lock {
        background-image: image(url("${./lock.svg}"));
        color: @foreground;
      }

      #lock:hover {
        color: @background;
      }

      #logout {
        background-image: image(url("${./logout.svg}"));
        color: @foreground;
      }

      #logout:hover {
        color: @background;
      }

      #suspend {
        background-image: image(url("${./suspend.svg}"));
        color: @foreground;
      }

      #suspend:hover {
        color: @background;
      }

      #hibernate {
        background-image: image(url("${./hibernate.svg}"));
        color: @foreground;
      }

      #hibernate:hover {
        color: @background;
      }

      #shutdown {
        background-image: image(url("${./shutdown.svg}"));
        color: @foreground;
      }

      #shutdown:hover {
        color: @background;
      }

      #reboot {
        background-image: image(url("${./reboot.svg}"));
        color: @foreground;
      }

      #reboot:hover {
        color: @background;
      }

      @define-color background ${colors.base00};
      @define-color foreground ${colors.yellow};

      ${builtins.readFile ./style.css}
    '';
  };
}
