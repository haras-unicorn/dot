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
        background-color={{ hexa (set-alpha ansi.main.black 0.5) }}
        text-color={{ hex ansi.main.white }}
        border-color={{ hex ansi.main.yellow }}
        progress-color={{ hex ansi.main.green }}
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
