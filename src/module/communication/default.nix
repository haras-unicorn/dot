{ self, pkgs, lib, config, ... }:

# FIXME: ferdium screen sharing and WebRTC
# NOTE: ferdium outlook - Self Hosted at https://outlook.office.com/mail/

let
  hasMonitor = config.dot.hardware.monitor.enable;
  monitorWidth = config.dot.hardware.monitor.width;
  monitorHeight = config.dot.hardware.monitor.height;

  ferdium = self.lib.chromium.wrap pkgs pkgs.ferdium "ferdium";
  slack = self.lib.chromium.wrap pkgs pkgs.slack "slack";
  teams = self.lib.chromium.wrap pkgs pkgs.teams-for-linux "teams-for-linux";
  vesktop = self.lib.chromium.wrap pkgs pkgs.vesktop "vesktop";

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
in
{
  config = lib.mkIf hasMonitor {
    desktopEnvironment.windowrules = [
      {
        rule = "float";
        selector = "class";
        xselector = "wm_class";
        arg = "ferdium";
        xarg = "ferdium";
      }
      {
        rule = "float";
        selector = "class";
        xselector = "wm_class";
        arg = "teams-for-linux";
        xarg = "teams-for-linux";
      }
      {
        rule = "float";
        selector = "class";
        xselector = "wm_class";
        arg = "vesktop";
        xarg = "vesktop";
      }
    ];
  };

  home = lib.mkIf hasMonitor {
    home.packages = [
      ferdium
      teams
      vesktop
      slack
    ];

    systemd.user.services.ferdium = {
      Unit = {
        Description = "Ferdium daemon";
        Requires = "tray.target";
        After = [ "graphical-session-pre.target" "tray.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service.ExecStart = "${ferdium}/bin/ferdium";
      Install.WantedBy = [ "graphical-session.target" ];
    };
    xdg.configFile."Ferdium/config/settings.json".text = builtins.toJSON
      ((builtins.fromJSON (builtins.readFile ./ferdium.json)) // {
        darkMode = config.stylix.polarity == "dark";
        accentColor = config.lib.stylix.colors.withHashtag.magenta;
        progressbarAccentColor = config.lib.stylix.colors.withHashtag.cyan;
      });
    xdg.configFile."Ferdium/config/window-state.json".text = builtins.toJSON windowState;
    xdg.configFile."Ferdium/window-state.json".text = builtins.toJSON windowState;

    xdg.configFile."teams-for-linux/config.json".text = builtins.toJSON {
      closeAppOnCross = true;
      trayIconEnabled = false;
    };
    xdg.configFile."teams-for-linux/window-state.json".text = builtins.toJSON windowState;
  };
}
