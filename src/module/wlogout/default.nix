{ config, ... }:

{
  home.shared = {
    programs.wlogout.enable = true;
    programs.wlogout.layout = [
      {
        label = "lock";
        action = "loginctl lock-session";
        text = "Lock";
        keybind = "l";
      }
      {
        label = "logout";
        action = "loginctl terminate-user $USER";
        text = "Logout";
        keybind = "e";
      }
      {
        label = "suspend";
        action = "systemctl suspend";
        text = "Suspend";
        keybind = "u";
      }
      {
        label = "hibernate";
        action = "systemctl hibernate";
        text = "Hibernate";
        keybind = "h";
      }
      {
        label = "reboot";
        action = "systemctl reboot";
        text = "Reboot";
        keybind = "r";
      }
      {
        label = "shutdown";
        action = "systemctl poweroff";
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

    programs.lulezojne.config.plop = [
      {
        template = ''
          @define-color background {{ rgba (set-alpha ansi.main.black 0.7) }};
          @define-color foreground {{ hex ansi.main.bright_white }};

          @define-color black {{ rgba ansi.main.black }};
          @define-color gray {{ rgba ansi.main.bright_black }};
          @define-color white {{ rgba ansi.main.white }};

          @define-color red {{ hex ansi.main.red }};
          @define-color green {{ hex ansi.main.green }};
          @define-color blue {{ hex ansi.main.blue }};
          @define-color cyan {{ hex ansi.main.cyan }};
          @define-color yellow {{ hex ansi.main.yellow }};
          @define-color magenta {{ hex ansi.main.magenta }};

          @define-color bright-red {{ hex ansi.main.bright_red }};
          @define-color bright-green {{ hex ansi.main.bright_green }};
          @define-color bright-blue {{ hex ansi.main.bright_blue }};
          @define-color bright-cyan {{ hex ansi.main.bright_cyan }};
          @define-color bright-yellow {{ hex ansi.main.bright_yellow }};
          @define-color bright-magenta {{ hex ansi.main.bright_magenta }};
        '';
        "in" = "${config.xdg.configHome}/wlogout/colors.css";
      }
    ];
  };
}
