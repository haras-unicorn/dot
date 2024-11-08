{ pkgs, lib, config, ... }:

let
  hasMonitor = config.dot.hardware.monitor.enable;
  hasKeyboard = config.dot.hardware.keyboard.enable;

in
{
  shared = (lib.mkIf (hasMonitor && hasKeyboard)) {
    dot = {
      desktopEnvironment.sessionStartup = [
        "${pkgs.keepassxc}/bin/keepassxc"
      ];

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

    services.gpg-agent.pinentryPackage = lib.mkMerge [
      (lib.mkIf hasMonitor pkgs.pinentry-qt)
      (lib.mkIf (!hasMonitor) pkgs.pinentry-curses)
    ];

    xdg.configFile."keepassxc/keepassxc.ini".source = lib.mkIf (hasMonitor && hasKeyboard) ./keepassxc.ini;
  };
}
