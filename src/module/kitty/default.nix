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

  bootstrap = config.dot.colors.bootstrap;
  terminal = config.dot.colors.terminal;
in
{
  config = {
    home.shared = {
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

        background_opacity 0.5

        foreground ${bootstrap.text.normal.hex}
        background ${bootstrap.background.normal.hex}

        color0     ${terminal.black.hex}
        color1     ${terminal.red.hex}
        color2     ${terminal.green.hex}
        color3     ${terminal.yellow.hex}
        color4     ${terminal.blue.hex}
        color5     ${terminal.magenta.hex}
        color6     ${terminal.cyan.hex}
        color7     ${terminal.white.hex}

        color8     ${terminal.brightBlack.hex}
        color9     ${terminal.brightRed.hex}
        color10    ${terminal.brightGreen.hex}
        color11    ${terminal.brightYellow.hex}
        color12    ${terminal.brightBlue.hex}
        color13    ${terminal.brightMagenta.hex}
        color14    ${terminal.brightCyan.hex}
        color15    ${terminal.brightWhite.hex}

        shell ${shell.package}/bin/${shell.bin}
        editor  ${editor.package}/bin/${editor.bin}

        ${vars}
      '';
    };
  };
}
