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
        color1  {{ hex (set-lightness ansi.main.red 0.6) }}
        color2  {{ hex (set-lightness ansi.main.green 0.6) }}
        color3  {{ hex (set-lightness ansi.main.yellow 0.6) }}
        color4  {{ hex (set-lightness ansi.main.blue 0.6) }}
        color5  {{ hex (set-lightness ansi.main.magenta 0.6) }}
        color6  {{ hex (set-lightness ansi.main.cyan 0.6) }}
        color7  {{ hex ansi.main.white }}

        color8  {{ hex ansi.main.bright_black }}
        color9  {{ hex (set-lightness ansi.main.bright_red 0.8) }}
        color10 {{ hex (set-lightness ansi.main.bright_green 0.8) }}
        color11 {{ hex (set-lightness ansi.main.bright_yellow 0.8) }}
        color12 {{ hex (set-lightness ansi.main.bright_blue 0.8) }}
        color13 {{ hex (set-lightness ansi.main.bright_magenta 0.8) }}
        color14 {{ hex (set-lightness ansi.main.bright_cyan 0.8) }}
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
