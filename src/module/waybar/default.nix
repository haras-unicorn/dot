{ pkgs, config, lib, ... }:

let
  bootstrap = config.dot.colors.bootstrap;
  terminal = config.dot.colors.terminal;
in
{
  shared = {
    dot = {
      desktopEnvironment.sessionStartup = [
        "${pkgs.waybar}/bin/waybar"
      ];
    };
  };

  home.shared = {
    xdg.configFile."waybar/colors.css".text = ''
      @define-color background ${bootstrap.background.hex};
      @define-color foreground ${bootstrap.text.hex};
      @define-color transparent ${bootstrap.background.rgba 0.4};

      @define-color secondary ${bootstrap.secondary.hex};

      @define-color black ${terminal.black.hex};
      @define-color white ${terminal.white.hex};

      @define-color red ${terminal.red.hex};
      @define-color green ${terminal.green.hex};
      @define-color blue ${terminal.blue.hex};
      @define-color cyan ${terminal.cyan.hex};
      @define-color yellow ${terminal.yellow.hex};
      @define-color magenta ${terminal.magenta.hex};

      @define-color bright-red ${terminal.brightRed.hex};
      @define-color bright-green ${terminal.brightGreen.hex};
      @define-color bright-blue ${terminal.brightBlue.hex};
      @define-color bright-cyan ${terminal.brightCyan.hex};
      @define-color bright-yellow ${terminal.brightYellow.hex};
      @define-color bright-magenta ${terminal.brightMagenta.hex};
    '';

    home.activation = {
      waybarReloadAction = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        ${pkgs.procps}/bin/pkill --signal "SIGUSR1" "waybar" || true
      '';
    };

    programs.waybar.enable = true;
    programs.waybar.settings = [
      (pkgs.lib.attrsets.recursiveUpdate
        (builtins.fromJSON (builtins.readFile ./config.json))
        {
          output = config.dot.mainMonitor;
          network = { interface = config.dot.networkInterface; };
          tray = {
            icon-size = config.dot.font.size.large;
          };
          temperature = {
            hwmon-path = config.dot.cpuHwmon;
          };
        })
    ];

    programs.waybar.style = ''
      @import "${config.xdg.configHome}/waybar/colors.css";

      * {
        font-family: '${config.dot.font.sans.name}';
        font-size: ${builtins.toString config.dot.font.size.large}px;
      }

      ${builtins.readFile ./style.css}
    '';
  };
}
