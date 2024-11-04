{ pkgs, lib, config, ... }:

let
  hasMonitor = config.dot.hardware.monitor.enable;
  hasKeyboard = config.dot.hardware.keyboard.enable;

  pinentry = lib.mkMerge [
    (lib.mkIf hasMonitor pkgs.pinentry-qt)
    (lib.mkIf (!hasMonitor) pkgs.pinentry-curser)
  ];
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
    home.packages = [
      (lib.mkIf (hasMonitor && hasKeyboard) pkgs.keepassxc)
      pinentry
    ];

    services.gpg-agent.pinentryPackage = pinentry;

    xdg.configFile."keepassxc/keepassxc.ini".source = lib.mkIf (hasMonitor && hasKeyboard) ./keepassxc.ini;
  };
}
