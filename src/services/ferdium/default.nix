{
  self,
  pkgs,
  lib,
  config,
  ...
}:

# FIXME: ferdium screen sharing and WebRTC
# NOTE: ferdium outlook - Self Hosted at https://outlook.office.com/mail/

let
  hasMonitor = config.dot.hardware.monitor.enable;
  monitorWidth = config.dot.hardware.monitor.width;
  monitorHeight = config.dot.hardware.monitor.height;

  ferdium = config.dot.chromium.wrap pkgs pkgs.ferdium "ferdium";
  slack = config.dot.chromium.wrap pkgs pkgs.slack "slack";
  teams = config.dot.chromium.wrap pkgs pkgs.teams-for-linux "teams-for-linux";
  vesktop = config.dot.chromium.wrap pkgs pkgs.vesktop "vesktop";

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

  mkFerdiumInstanceConfig =
    instanceName:
    let
      dataDir = "${config.xdg.dataHome}/ferdium/${instanceName}";
      prefix = "ferdium/${instanceName}";
    in
    {
      systemd.user.services."ferdium@${instanceName}" = {
        Unit = {
          Description = "Ferdium (${instanceName})";
          After = [ "graphical-session.target" ];
          Requires = [ "graphical-session.target" ];
        };
        Service = {
          ExecStartPre = [
            "${pkgs.coreutils}/bin/mkdir -p ${dataDir}/config"
          ];
          ExecStart = "${ferdium}/bin/ferdium --user-data-dir=${dataDir}";
          Restart = "on-failure";
          WorkingDirectory = dataDir;
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };

      xdg.dataFile."${prefix}/config/settings.json".text = builtins.toJSON settings;

      xdg.dataFile."${prefix}/config/window-state.json".text = builtins.toJSON windowState;
      xdg.dataFile."${prefix}/window-state.json".text = builtins.toJSON windowState;
    };
in
{
  homeManagerModule = lib.mkIf hasMonitor (
    lib.mkMerge [
      {
        dot.desktopEnvironment.windowrules = [
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
      }
      (mkFerdiumInstanceConfig "personal")
      # (mkFerdiumInstanceConfig "work")
    ]
  );
}
