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
        color0  {{ hex ansi.main.black }}
        color1  {{ hex ansi.main.red }}
        color2  {{ hex ansi.main.green }}
        color3  {{ hex ansi.main.yellow }}
        color4  {{ hex ansi.main.blue }}
        color5  {{ hex ansi.main.magenta }}
        color6  {{ hex ansi.main.cyan }}
        color7  {{ hex ansi.main.white }}
        color8  {{ hex ansi.main.bright_black }}
        color9  {{ hex ansi.main.bright_red }}
        color10 {{ hex ansi.main.bright_green }}
        color11 {{ hex ansi.main.bright_yellow }}
        color12 {{ hex ansi.main.bright_blue }}
        color13 {{ hex ansi.main.bright_magenta }}
        color14 {{ hex ansi.main.bright_cyan }}
        color15 {{ hex ansi.main.bright_white }}
      '';
      "in" = "${config.xdg.configHome}/kitty/colors.conf";
      "then" = {
        command = "pkill";
        args = [ "--signal" "SIGUSR1" "kitty" ];
      };
    }
  ];

  wayland.windowManager.hyprland.extraConfig = ''
    bind = super, t, exec, ${pkgs.kitty}/bin/kitty
  '';
}
