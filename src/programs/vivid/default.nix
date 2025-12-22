{ pkgs, config, ... }:

{
  homeManagerModule = {
    dot.shell.sessionVariables = {
      LS_COLORS = "vivid generate ${config.xdg.configHome}/vivid/themes/colors.yaml";
    };

    xdg.configFile."vivid/themes/colors.yaml".text = ''
      colors:
        black: "${config.lib.stylix.colors.base00}"
        red: "${config.lib.stylix.colors.red}"
        green: "${config.lib.stylix.colors.green}"
        blue: "${config.lib.stylix.colors.blue}"
        magenta: "${config.lib.stylix.colors.magenta}"
        yellow: "${config.lib.stylix.colors.yellow}"
        cyan: "${config.lib.stylix.colors.cyan}"
        brown: "${config.lib.stylix.colors.brown}"

      ${builtins.readFile ./colors.yaml}
    '';

    home.packages = [
      pkgs.vivid
    ];
  };
}
