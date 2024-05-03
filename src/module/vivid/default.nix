{ pkgs, config, ... }:

{
  shared = {
    dot = {
      shell.sessionVariables = {
        LS_COLORS = "vivid generate lulezojne";
      };
    };
  };

  home.shared = {
    # TODO: try then https://unix.stackexchange.com/a/38212
    programs.lulezojne.config.plop = [
      {
        template = builtins.readFile ./lulezojne.yaml;
        "in" = "${config.xdg.configHome}/vivid/themes/lulezojne.yaml";
      }
    ];

    home.packages = with pkgs; [
      vivid
    ];
  };
}
