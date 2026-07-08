{
  self.lib.deprecated.homeModules.wlogout =
    {
      pkgs,
      lib,
      osConfig,
      config,
      ...
    }:
    let
      colors = config.lib.stylix.colors.withHashtag;

      hardware = osConfig.dot.hardware;
    in
    lib.mkIf (hardware.graphics && hardware.pointing && hardware.wayland) {
      dot.desktop.logout = "${lib.getExe pkgs.wlogout} -p layer-shell";

      programs.wlogout.enable = true;
      programs.wlogout.layout = [
        {
          label = "lock";
          action = "${lib.getExe' pkgs.systemd "loginctl"} lock-session";
          text = "Lock";
          keybind = "l";
        }
        {
          label = "logout";
          action = "${lib.getExe' pkgs.systemd "loginctl"} terminate-user $USER";
          text = "Logout";
          keybind = "e";
        }
        {
          label = "suspend";
          action = "${lib.getExe' pkgs.systemd "systemctl"} suspend-then-hibernate";
          text = "Suspend";
          keybind = "u";
        }
        {
          label = "hibernate";
          action = "${lib.getExe' pkgs.systemd "systemctl"} hibernate";
          text = "Hibernate";
          keybind = "h";
        }
        {
          label = "reboot";
          action = "${lib.getExe' pkgs.systemd "systemctl"} reboot";
          text = "Reboot";
          keybind = "r";
        }
        {
          label = "shutdown";
          action = "${lib.getExe' pkgs.systemd "systemctl"} poweroff";
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
