{ pkgs, config, ... }:

{
  shared = {
    dot = {
      desktopEnvironment.sessionStartup = [ "${pkgs.mako}/bin/mako" ];
    };
  };

  home.shared = {
    home.packages = with pkgs; [
      libnotify
      mako
    ];

    programs.lulezojne.config.plop = [
      {
        template = ''
          font="${config.dot.font.sans.name}" ${builtins.toString config.dot.font.size.large}
          width=512
          height=256

          margin=32
          padding=8
          border-size=2
          border-radius=4
          icons=1
          max-icon-size=128
          default-timeout=10000
          anchor=bottom-right

          background-color={{ hexa ansi.main.black }}
          text-color={{ hex ansi.main.bright_white }}
          border-color={{ hex ansi.main.bright_yellow }}
          progress-color={{ hex ansi.main.bright_green }}
        '';
        "in" = "${config.xdg.configHome}/mako/config";
        "then" = {
          command = "${pkgs.mako}/bin/makoctl";
          args = [ "reload" ];
        };
      }
    ];
  };
}