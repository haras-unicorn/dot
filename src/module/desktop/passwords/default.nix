{ pkgs, lib, config, ... }:

let
  hasMonitor = config.dot.hardware.monitor.enable;
  hasKeyboard = config.dot.hardware.keyboard.enable;
in
{
  options = {
    pinentry.package = lib.mkOption {
      type = lib.types.package;
      default =
        if hasMonitor
        then pkgs.pinentry-qt
        else pkgs.pinentry-curses;
    };
    pinentry.bin = lib.mkOption {
      type = lib.types.str;
      default =
        if hasMonitor
        then "pinentry-qt"
        else "pinentry-curses";
    };
  };

  config = {
    shared = (lib.mkIf (hasMonitor && hasKeyboard)) {
      dot = {
        desktopEnvironment.windowrules = [{
          rule = "float";
          selector = "class";
          xselector = "wm_class";
          arg = "org.keepassxc.KeePassXC";
          xarg = "keepassxc";
        }];
      };
    };

    home = {
      home.packages = lib.optionals hasMonitor [
        pkgs.pinentry-qt
      ] ++ lib.optionals (!hasMonitor) [
        pkgs.pinentry-curses
      ] ++ lib.optionals (hasMonitor && hasKeyboard) [
        pkgs.keepassxc
      ];

      services.gpg-agent.pinentryPackage =
        lib.mkMerge [
          (lib.mkIf hasMonitor pkgs.pinentry-qt)
          (lib.mkIf (!hasMonitor) pkgs.pinentry-curses)
        ];

      xdg.configFile."keepassxc/keepassxc.ini" = lib.mkIf (hasMonitor && hasKeyboard) {
        source = ./keepassxc.ini;
      };

      systemd.user.services.keepassxc = lib.mkIf (hasMonitor && hasKeyboard) {
        Unit = {
          Description = "keepassxc daemon";
          Requires = "tray.target";
          After = [ "graphical-session-pre.target" "tray.target" ];
          PartOf = [ "graphical-session.target" ];
        };
        Service.ExecStart = "${pkgs.keepassxc}/bin/keepassxc";
        Install.WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
