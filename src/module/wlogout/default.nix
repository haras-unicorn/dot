{ pkgs, config, ... }:

let
  bootstrap = config.dot.colors.bootstrap;
  terminal = config.dot.colors.terminal;
in
{
  home.shared = {
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
      @import "${config.xdg.configHome}/wlogout/colors.css";

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

      ${builtins.readFile ./style.css}
    '';

    xdg.configFile."wlogout/colors.css".text = ''
      @define-color background ${bootstrap.background};
      @define-color foreground ${bootstrap.text};

      @define-color black ${terminal.black};
      @define-color gray ${terminal.white};
      @define-color white ${terminal.brightWhite};

      @define-color red ${terminal.red};
      @define-color green ${terminal.green};
      @define-color blue ${terminal.blue};
      @define-color cyan ${terminal.cyan};
      @define-color yellow ${terminal.yellow};
      @define-color magenta ${terminal.magenta};

      @define-color bright-red ${terminal.brightRed};
      @define-color bright-green ${terminal.brightGreen};
      @define-color bright-blue ${terminal.brightBlue};
      @define-color bright-cyan ${terminal.brightCyan};
      @define-color bright-yellow ${terminal.brightYellow};
      @define-color bright-magenta ${terminal.brightMagenta};
    '';
  };
}
