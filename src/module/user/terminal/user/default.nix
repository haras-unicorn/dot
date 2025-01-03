{ pkgs, lib, config, ... }:

# NOTE: install everywhere to enable full ssh compatibility

let
  hasMonitor = config.dot.hardware.monitor.enable;
  hasKeyboard = config.dot.hardware.keyboard.enable;

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
    terminal = { package = pkgs.kitty; bin = "kitty"; };
  };

  home = {
    programs.kitty.enable = true;
    programs.kitty.extraConfig = lib.mkIf (hasKeyboard && hasMonitor) ''
      ${builtins.readFile ./kitty.conf}

      font_family      ${font.nerd.name}
      bold_font        ${font.nerd.name}
      italic_font      ${font.nerd.name}
      bold_italic_font ${font.nerd.name}
      font_size        ${builtins.toString font.size.medium}

      background_opacity 0.75

      foreground ${bootstrap.text.normal.hex}
      background ${bootstrap.background.normal.hex}

      color0     ${terminal.black.normal.hex}
      color1     ${terminal.red.normal.hex}
      color2     ${terminal.green.normal.hex}
      color3     ${terminal.yellow.normal.hex}
      color4     ${terminal.blue.normal.hex}
      color5     ${terminal.magenta.normal.hex}
      color6     ${terminal.cyan.normal.hex}
      color7     ${terminal.white.normal.hex}

      color8     ${terminal.brightBlack.normal.hex}
      color9     ${terminal.brightRed.normal.hex}
      color10    ${terminal.brightGreen.normal.hex}
      color11    ${terminal.brightYellow.normal.hex}
      color12    ${terminal.brightBlue.normal.hex}
      color13    ${terminal.brightMagenta.normal.hex}
      color14    ${terminal.brightCyan.normal.hex}
      color15    ${terminal.brightWhite.normal.hex}

      shell ${shell.package}/bin/${shell.bin}
      editor  ${editor.package}/bin/${editor.bin}

      ${vars}
    '';
  };
}
