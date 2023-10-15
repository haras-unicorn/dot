{ pkgs, config, ... }:

{
  programs.kitty.enable = true;
  programs.kitty.extraConfig = ''
    ${builtins.readFile ./kitty.conf}
    include colors.conf
  '';

  programs.lulezojne.config.plop = [
    {
      template = ''
        color0 {{ hex ansi.main.black }}
        color8 {{ hex ansi.main.bright_black }}
        color7  {{ hex ansi.main.white }}
        color15 {{ hex ansi.main.bright_white }}
        color3  {{ hex ansi.main.yellow }}
        color11 {{ hex ansi.main.bright_yellow }}
        color1 {{ hex ansi.main.red }}
        color9 {{ hex ansi.main.bright_red }}
        color5  {{ hex ansi.main.magenta }}
        color13 {{ hex ansi.main.bright_magenta }}
        color4  {{ hex ansi.main.blue }}
        color12 {{ hex ansi.main.bright_blue }}
        color6  {{ hex ansi.main.cyan }}
        color14 {{ hex ansi.main.bright_cyan }}
        color2  {{ hex ansi.main.green }}
        color10 {{ hex ansi.main.bright_green }}
      '';
      "in" = "${config.xdg.configHome}/kitty/colors.conf";
    }
  ];

  wayland.windowManager.hyprland.extraConfig = ''
    bind = super, t, exec, ${pkgs.kitty}/bin/kitty
  '';
}
