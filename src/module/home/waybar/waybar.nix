{ hardware, pkgs, config, ... }:

{
  programs.waybar.enable = true;
  programs.waybar.settings = [
    {
      output = hardware.mainMonitor;
      network = { interface = hardware.networkInterface; };
    }
    (builtins.fromJSON (builtins.readFile ./config.json))
  ];
  programs.waybar.style = ''
    @import "${config.xdg.configHome}/waybar/colors.css";

    ${builtins.readFile ./style.css}
  '';

  programs.lulezojne.config = {
    plop = [
      {
        template = ''
          @define-color background {{ rgba (set-alpha ansi.main.black 0.3) }};
          @define-color foreground {{ hex ansi.main.white }};

          @define-color black {{ rgba (set-alpha ansi.main.black 0.5) }};
          @define-color white {{ rgba (set-alpha ansi.main.white 0.5) }};

          @define-color red {{ hex ansi.main.red }};
          @define-color green {{ hex ansi.main.green }};
          @define-color blue {{ hex ansi.main.blue }};
          @define-color cyan {{ hex ansi.main.cyan }};
          @define-color yellow {{ hex ansi.main.yellow }};
          @define-color magenta {{ hex ansi.main.magenta }};
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
