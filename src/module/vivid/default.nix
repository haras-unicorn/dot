{ pkgs, config, ... }:

let
  terminal = config.dot.colors.terminal;

  toVividColor = x: builtins.substring 1 (-1) x;
in
{
  shared = {
    dot = {
      shell.sessionVariables = {
        LS_COLORS = "vivid generate colors";
      };
    };
  };

  home.shared = {
    xdg.configFile."vidid/themes/colors.yaml".text = ''
      colors:
        black: "${toVividColor terminal.black}"
        green: "${toVividColor terminal.green}"
        purple: "${toVividColor terminal.magenta}"
        red: "${toVividColor terminal.red}"
        yellow: "${toVividColor terminal.brightYellow}"
        cyan: "${toVividColor terminal.cyan}"
        pink: "${toVividColor terminal.brightMagenta}"
        orange: "${toVividColor terminal.yellow}"
        white: "${toVividColor terminal.brightWhite}"
        base01: "${toVividColor terminal.white}"

      ${builtins.readFile ./colors.yaml}
    '';

    home.packages = with pkgs; [
      vivid
    ];
  };
}
