{ pkgs, config, ... }:

{
  home.packages = with pkgs; [
    keepmenu
  ];

  programs.wofi.enable = true;

  wayland.windowManager.hyprland.extraConfig = ''
    bind = super, return, exec, ${pkgs.wofi}/bin/wofi --show drun
  '';

  programs.wofi.style = ''
    @import "${config.xdg.configHome}/wofi/colors.css";

    ${builtins.readFile ./style.css}
  '';

  programs.lulezojne.config.plop = [
    {
      template = ''
        @define-color background {{ rgba (set-alpha ansi.main.black 0.7) }};
        @define-color foreground {{ hex ansi.main.bright_white }};

        @define-color black {{ rgba ansi.main.black }};
        @define-color brey {{ rgba ansi.main.bright_black }};
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
      "in" = "${config.xdg.configHome}/wofi/colors.css";
    }
  ];
}
