{ pkgs, config, ... }:

let
  terminal = config.dot.colors.terminal;
in
{
  shared = {
    dot = {
      shell.sessionVariables = {
        LS_COLORS = "vivid generate ${config.xdg.configHome}/vivid/themes/colors.yaml";
      };
    };
  };

  home.shared = {
    xdg.configFile."vivid/themes/colors.yaml".text = ''
      colors:
        black: "${terminal.black.normal.vivid}"
        green: "${terminal.green.normal.vivid}"
        purple: "${terminal.magenta.normal.vivid}"
        red: "${terminal.red.normal.vivid}"
        yellow: "${terminal.brightYellow.normal.vivid}"
        cyan: "${terminal.cyan.normal.vivid}"
        pink: "${terminal.brightMagenta.normal.vivid}"
        orange: "${terminal.yellow.normal.vivid}"
        white: "${terminal.brightWhite.normal.vivid}"
        base01: "${terminal.white.normal.vivid}"

      ${builtins.readFile ./colors.yaml}
    '';

    home.packages = with pkgs; [
      vivid
    ];
  };
}
