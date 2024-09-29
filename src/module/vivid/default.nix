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
        black: "${terminal.black.vivid}"
        green: "${terminal.green.vivid}"
        purple: "${terminal.magenta.vivid}"
        red: "${terminal.red.vivid}"
        yellow: "${terminal.brightYellow.vivid}"
        cyan: "${terminal.cyan.vivid}"
        pink: "${terminal.brightMagenta.vivid}"
        orange: "${terminal.yellow.vivid}"
        white: "${terminal.brightWhite.vivid}"
        base01: "${terminal.white.vivid}"

      ${builtins.readFile ./colors.yaml}
    '';

    home.packages = with pkgs; [
      vivid
    ];
  };
}
