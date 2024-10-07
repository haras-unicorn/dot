{ pkgs, config, lib, ... }:

let
  bootstrap = config.dot.colors.bootstrap;
in
{
  home.shared = {
    xdg.configFile."waybar/colors.css".text = ''
      @define-color transparent ${bootstrap.background.normal.rgba 0.4};
      @define-color text ${bootstrap.text.normal.hex};
      @define-color text-alternate ${bootstrap.text.alternate.hex};
      @define-color primary ${bootstrap.primary.normal.hex};
      @define-color secondary ${bootstrap.secondary.normal.hex};
      @define-color accent ${bootstrap.accent.normal.hex};
    '';

    home.activation = {
      waybarReloadAction = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        ${pkgs.procps}/bin/pkill --signal "SIGUSR1" "waybar" || true
      '';
    };

    programs.waybar.enable = true;
    programs.waybar.systemd.enable = true;
    programs.waybar.settings = [
      (pkgs.lib.attrsets.recursiveUpdate
        (builtins.fromJSON (builtins.readFile ./config.json))
        {
          output = config.dot.mainMonitor;
          network = { interface = config.dot.networkInterface; };
          tray = {
            icon-size = config.dot.font.size.large;
          };
          temperature = {
            hwmon-path = config.dot.cpuHwmon;
          };
        })
    ];

    programs.waybar.style = ''
      @import "${config.xdg.configHome}/waybar/colors.css";

      * {
        font-family: '${config.dot.font.sans.name}';
        font-size: ${builtins.toString config.dot.font.size.large}px;
      }

      ${builtins.readFile ./style.css}
    '';
  };
}
