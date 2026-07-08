# NOTE: ferdium outlook - Self Hosted at https://outlook.office.com/mail/
# TODO: use network isolation when adding VPN
{
  machines.nixosModules.ferdium =
    { lib, config, ... }:
    let
      hardware = config.dot.hardware;
    in
    lib.mkIf hardware.browser {
      dot.nixpkgs.allowUnfreePredicates = [
        (
          package:
          let
            name = lib.getName package;
          in
          name == "slack"
        )
      ];
    };

  machines.homeModules.ferdium =
    {
      config,
      osConfig,
      lib,
      pkgs,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;
      monitorWidth = hardware.width;
      monitorHeight = hardware.height;

      ferdium = osConfig.dot.programs.chromium.wrap pkgs.ferdium "ferdium";
      slack = osConfig.dot.programs.chromium.wrap pkgs.slack "slack";
      teams = osConfig.dot.programs.chromium.wrap pkgs.teams-for-linux "teams-for-linux";
      vesktop = osConfig.dot.programs.chromium.wrap pkgs.vesktop "vesktop";

      windowState = {
        width = monitorWidth * 3 / 4;
        height = monitorHeight * 3 / 4;
        x = monitorWidth / 4;
        y = monitorHeight / 4;
        displayBounds = {
          x = 0;
          y = 0;
          width = monitorWidth;
          height = monitorHeight;
        };
        isMaximized = true;
        isFullScreen = false;
      };

      settings = (builtins.fromJSON (builtins.readFile ./ferdium.json)) // {
        darkMode = config.stylix.polarity == "dark";
        accentColor = config.lib.stylix.colors.withHashtag.magenta;
        progressbarAccentColor = config.lib.stylix.colors.withHashtag.cyan;
      };

      dataDir = "${config.xdg.dataHome}/ferdium";
      prefix = "ferdium";
    in
    lib.mkIf hardware.browser {
      dot.desktop.windowrules = [
        {
          rule = "float";
          selector = "class";
          arg = "ferdium";
        }
        {
          rule = "float";
          selector = "class";
          arg = "teams-for-linux";
        }
        {
          rule = "float";
          selector = "class";
          arg = "vesktop";
        }
      ];

      home.packages = [
        ferdium
        teams
        vesktop
        slack
      ];

      xdg.configFile."teams-for-linux/config.json".text = builtins.toJSON {
        closeAppOnCross = true;
        trayIconEnabled = false;
      };
      xdg.configFile."teams-for-linux/window-state.json".text = builtins.toJSON windowState;

      systemd.user.services.ferdium = {
        Install.WantedBy = [ "graphical-session.target" ];
        Unit = {
          Description = "Ferdium";
          After = [
            "tray.target"
            "graphical-session.target"
          ];
          PartOf = [ "graphical-session.target" ];
          Requires = [ "tray.target" ];
        };
        Service = {
          ExecStart = "${ferdium}/bin/ferdium --user-data-dir=${dataDir}";
          Restart = "on-failure";
          WorkingDirectory = dataDir;
          KillMode = "mixed";
          TimeoutStopSec = 15;
        };
      };

      xdg.dataFile."${prefix}/config/settings.json".text = builtins.toJSON settings;
      xdg.dataFile."${prefix}/config/window-state.json".text = builtins.toJSON windowState;
      xdg.dataFile."${prefix}/window-state.json".text = builtins.toJSON windowState;
    };
}
