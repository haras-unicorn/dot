{ self, pkgs, lib, config, ... }:

# FIXME: ferdium screen sharing and WebRTC
# NOTE: ferdium outlook - Self Hosted at https://outlook.office.com/mail/

let
  isLightTheme = config.dot.colors.isLightTheme;
  bootstrap = config.dot.colors.bootstrap;

  hasMonitor = config.dot.hardware.monitor.enable;

  ferdium = self.lib.electron.wrap pkgs pkgs.ferdium "ferdium";
  slack = self.lib.electron.wrap pkgs pkgs.slack "slack";
  teams = self.lib.electron.wrap pkgs pkgs.teams-for-linux "teams-for-linux";
  vesktop = self.lib.electron.wrap pkgs pkgs.vesktop "vesktop";
in
{
  shared = lib.mkIf hasMonitor {
    dot = {
      desktopEnvironment.windowrules = [{
        rule = "float";
        selector = "class";
        xselector = "wm_class";
        arg = "ferdium";
        xarg = "ferdium";
      }];
    };
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
        darkMode = !isLightTheme;
        accentColor = bootstrap.primary.normal.hex;
        progressbarAccentColor = bootstrap.primary.alternate.hex;
      });
  };
}
