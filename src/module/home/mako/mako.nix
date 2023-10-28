{ pkgs, config, ... }:

{
  home.packages = with pkgs; [
    libnotify
  ];

  services.mako.enable = true;
  xdg.configFile."mako/config".enable = false;

  programs.lulezojne.config.plop = [
    {
      template = ''
        background-color={{ hexa ansi.main.black }}
        text-color={{ hex ansi.main.bright_white }}
        border-color={{ hex ansi.main.bright_yellow }}
        progress-color={{ hex ansi.main.bright_green }}
      '';
      "in" = "${config.xdg.configHome}/mako/config";
      "then" = {
        command = "${pkgs.writeShellApplication {
          name = "mako-lulezojne";
          text = ''
            ${config.services.mako.package}/bin/makoctl reload
          '';
        }}/bin/mako-lulezojne";
      };
    }
  ];
}
