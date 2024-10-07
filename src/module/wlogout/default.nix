{ pkgs, config, ... }:

let
  bootstrap = config.dot.colors.bootstrap;

  logout = pkgs.writeShellApplication {
    name = "logout";
    runtimeInputs = [ pkgs.wlogout ];
    text = ''
      exec wlogout -p layer-shell
    '';
  };
in
{
  home.shared = {
    home.packages = [
      logout
    ];

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
        font-family: '${config.dot.font.sans.name}';
        font-size: ${builtins.toString config.dot.font.size.large}px;
      }

      #lock {
        background-image: image(url("${./lock.svg}"));
      }

      #logout {
        background-image: image(url("${./logout.svg}"));
      }

      #suspend {
        background-image: image(url("${./suspend.svg}"));
      }

      #hibernate {
        background-image: image(url("${./hibernate.svg}"));
      }

      #shutdown {
        background-image: image(url("${./shutdown.svg}"));
      }

      #reboot {
        background-image: image(url("${./reboot.svg}"));
      }

      @define-color background ${bootstrap.text.normal.hex};
      @define-color foreground ${bootstrap.background.normal.hex};

      ${builtins.readFile ./style.css}
    '';
  };
}
