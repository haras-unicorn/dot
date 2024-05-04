{ pkgs, lib, config, ... }:

let
  cfg = config.dot.terminal;

  vars = lib.strings.concatStringsSep
    "\n"
    (builtins.map
      (name: "env ${name}=${builtins.toString cfg.sessionVariables."${name}"}")
      (builtins.attrNames cfg.sessionVariables));

  shell = config.dot.shell;
  editor = config.dot.editor;
  font = config.dot.font;
in
{
  config = {
    home.shared = {
      programs.lulezojne.config.plop = [
        {
          template = ''
            background_opacity 0.5

            foreground {{ hex (set-lightness ansi.main.bright_white 0.9) }}
            background {{ hex (set-lightness ansi.main.black 0.1) }}

            color0     {{ hex ansi.main.black }}
            color1     {{ hex (set-lightness ansi.main.red 0.7) }}
            color2     {{ hex (set-lightness ansi.main.green 0.7) }}
            color3     {{ hex (set-lightness ansi.main.yellow 0.7) }}
            color4     {{ hex (set-lightness ansi.main.blue 0.7) }}
            color5     {{ hex (set-lightness ansi.main.magenta 0.7) }}
            color6     {{ hex (set-lightness ansi.main.cyan 0.7) }}
            color7     {{ hex (set-lightness ansi.main.white 0.7) }}

            color8     {{ hex (set-lightness ansi.main.bright_black 0.5) }}
            color9     {{ hex (set-lightness ansi.main.bright_red 0.9) }}
            color10    {{ hex (set-lightness ansi.main.bright_green 0.9) }}
            color11    {{ hex (set-lightness ansi.main.bright_yellow 0.9) }}
            color12    {{ hex (set-lightness ansi.main.bright_blue 0.9) }}
            color13    {{ hex (set-lightness ansi.main.bright_magenta 0.9) }}
            color14    {{ hex (set-lightness ansi.main.bright_cyan 0.9) }}
            color15    {{ hex ansi.main.bright_white }}
          '';
          "in" = "${config.xdg.configHome}/kitty/colors.conf";
          "then" = {
            command = "pkill";
            args = [ "--signal" "SIGUSR1" "kitty" ];
          };
        }
      ];

      programs.kitty.enable = true;
      programs.kitty.package =
        (p: yes: no: lib.mkMerge [
          (lib.mkIf p yes)
          (lib.mkIf (!p) no)
        ])
          (cfg.bin == "kitty")
          cfg.package
          pkgs.nushell;

      programs.kitty.extraConfig = ''
        ${builtins.readFile ./kitty.conf}

        font_family      ${font.nerd.name}
        bold_font        ${font.nerd.name}
        italic_font      ${font.nerd.name}
        bold_italic_font ${font.nerd.name}
        font_size        ${builtins.toString font.size.medium}

        include colors.conf

        shell ${shell.package}/bin/${shell.bin}
        editor  ${editor.package}/bin/${editor.bin}

        ${vars}
      '';
    };
  };
}