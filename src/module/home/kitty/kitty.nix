{ pkgs, config, ... }:

{
  programs.kitty.enable = true;

  xdg.configFile."kitty/kitty.conf".enable = false;
  programs.lulezojne.config.plop = [
    {
      template = ''
        ${builtins.readFile ./kitty.conf}

        #: black
        color0 {{ hex ansi.main.black }}
        color8 {{ hex ansi.main.bright_black }}

        #: white
        color7  {{ hex ansi.main.white }}
        color15 {{ hex ansi.main.bright_white }}

        #: yellow
        color3  {{ hex ansi.main.yellow }}
        color11 {{ hex ansi.main.bright_yellow }}

        #: red
        color1 {{ hex ansi.main.red }}
        color9 {{ hex ansi.main.bright_red }}

        #: magenta
        color5  {{ hex ansi.main.magenta }}
        color13 {{ hex ansi.main.bright_magenta }}

        #: blue
        color4  {{ hex ansi.main.blue }}
        color12 {{ hex ansi.main.bright_blue }}

        #: cyan
        color6  {{ hex ansi.main.cyan }}
        color14 {{ hex ansi.main.bright_cyan }}

        #: green
        color2  {{ hex ansi.main.green }}
        color10 {{ hex ansi.main.bright_green }}
      '';
      "in" = "${config.xdg.configHome}/kitty/kitty.conf";
    }
  ];

  wayland.windowManager.hyprland.extraConfig = ''
    bind = super, t, exec, ${pkgs.kitty}/bin/kitty
  '';
}
