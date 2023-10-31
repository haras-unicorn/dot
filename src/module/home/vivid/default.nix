{ pkgs, config, ... }:

{
  # TODO: make it work with hyprland?
  programs.nushell.environmentVariables = {
    LS_COLORS = "(vivid generate lulezojne | str trim)";
  };

  # TODO: then option when https://github.com/sharkdp/vivid/issues/116
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
