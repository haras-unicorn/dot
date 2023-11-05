{ pkgs, config, ... }:

{
  shell.sessionVariables = {
    LS_COLORS = "vivid generate lulezojne";
  };

  # TODO: try then https://unix.stackexchange.com/a/38212
  programs.lulezojne.config.plop = [
    {
      template = builtins.readFile ./lulezojne.yml.hbs;
      "in" = "${config.xdg.configHome}/vivid/themes/lulezojne.yml";
    }
  ];

  home.packages = with pkgs; [
    vivid
  ];
}
