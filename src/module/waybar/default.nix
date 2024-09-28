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
      @define-color background ${bootstrap.background};
      @define-color foreground ${bootstrap.text};

      @define-color black ${terminal.black};
      @define-color white ${terminal.white};

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

    home.activation = {
      waybarReloadAction = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        ${pkgs.procps}/bin/pkill --signal "SIGUSR1" "waybar"
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
