{ pkgs, config, ... }:

# TODO: use instead of waybar after https://github.com/elkowar/eww/pull/743
# TODO: hook up config like with waybar

let
  package = pkgs.eww;
  bin = "${package}/bin/eww";
in
{
  home.shared = {
    de.sessionStartup = [
      "${bin} daemon"
    ];

    de.keybinds = [
      {
        mods = [ "super" ];
        key = "s";
        command = "${bin} open --toggle sysinfo";
      }
    ];

    home.packages = [
      package
    ];

    # programs.eww.enable = true;
    # programs.eww.package = package;
    # programs.eww.configDir = ./config;

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
          "in" = "${config.xdg.configHome}/eww/colors.css";
          "then" = {
            command = "eww";
            args = [ "reload" ];
          };
        }
      ];
    };
  };
}
