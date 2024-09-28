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

        foreground ${bootstrap.text}
        background ${bootstrap.background}

        color0     ${terminal.black}
        color1     ${terminal.red}
        color2     ${terminal.green}
        color3     ${terminal.yellow}
        color4     ${terminal.blue}
        color5     ${terminal.magenta}
        color6     ${terminal.cyan}
        color7     ${terminal.white}

        color8     ${terminal.brightBlack}
        color9     ${terminal.brightRed}
        color10    ${terminal.brightGreen}
        color11    ${terminal.brightYellow}
        color12    ${terminal.brightBlue}
        color13    ${terminal.brightMagenta}
        color14    ${terminal.brightCyan}
        color15    ${terminal.brightWhite}

        shell ${shell.package}/bin/${shell.bin}
        editor  ${editor.package}/bin/${editor.bin}

        ${vars}
      '';
    };
  };
}
