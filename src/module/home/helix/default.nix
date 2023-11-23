{ config, ... }:

{
  programs.lulezojne.config.plop = [
    {
      template = builtins.readFile ./lulezojne.toml;
      "in" = "${config.xdg.configHome}/helix/themes/lulezojne.toml";
      "then" = {
        command = "pkill";
        args = [ "--signal" "SIGUSR1" "hx" ];
      };
    }
  ];

  programs.helix.enable = true;

  programs.helix.settings = builtins.fromTOML (builtins.readFile ./settings.toml);
}
