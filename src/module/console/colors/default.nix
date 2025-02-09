{ pkgs, config, ... }:

{
  config = {
    shell.sessionVariables = {
      LS_COLORS = "vivid generate ${config.xdg.configHome}/vivid/themes/colors.yaml";
    };
  };

  home = {
    xdg.configFile."vivid/themes/colors.yaml".text = ''
      colors:
        black: "${config.lib.stylix.colors.base00}"
        green: "${config.lib.stylix.colors.green}"
        purple: "${config.lib.stylix.colors.purple}"
        red: "${config.lib.stylix.colors.red}"
        yellow: "${config.lib.stylix.colors.yellow}"
        cyan: "${config.lib.stylix.colors.cyan}"
        pink: "${config.lib.stylix.colors.pink}"
        orange: "${config.lib.stylix.colors.orange}"
        white: "${config.lib.stylix.colors.base15}"
        base01: "${config.lib.stylix.colors.base01}"

      ${builtins.readFile ./colors.yaml}
    '';

    home.packages = [
      pkgs.vivid
    ];
  };
}
