{ hardware, pkgs, config, ... }:

{
  programs.waybar.enable = true;
  programs.waybar.settings = [
    (pkgs.lib.attrsets.recursiveUpdate
      (builtins.fromJSON (builtins.readFile ./config.json))
      {
        output = hardware.mainMonitor;
        network = { interface = hardware.networkInterface; };
        tray = {
          icon-size = 14;
        };
        temperature = {
          hwmon-path = hardware.hwmon;
        };
      })
  ];
  programs.waybar.style = ''
    @import "${config.xdg.configHome}/waybar/colors.css";

    #waybar {
      font-size: 14px;
    }

    ${builtins.readFile ./style.css}
  '';

  programs.lulezojne.config = {
    plop = [
      {
        template = ''
          @define-color background {{ rgba (set-alpha ansi.main.black 0.7) }};
          @define-color foreground {{ hex ansi.main.white }};

          @define-color black {{ rgba ansi.main.black }};
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
        "in" = "${config.xdg.configHome}/waybar/colors.css";
        "then" = {
          command = "${pkgs.writeShellApplication {
            name = "waybar-lulezojne";
            text = ''
              # NOTE: only kill those that don't match this script
              IFS=$'\n' read -r -a pids <<< "$(pgrep -f waybar)"
              for pid in "''${pids[@]}"; do
                if [[ $pid != "$$" ]]; then
                  kill "$pid"
                fi
              done

              waybar >/dev/null 2>&1 & disown
            '';
          }}/bin/waybar-lulezojne";
        };
      }
    ];
  };

  wayland.windowManager.hyprland.extraConfig = ''
    exec-once = ${pkgs.waybar}/bin/waybar
  '';
}
