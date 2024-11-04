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

  home = (lib.mkIf (hasMonitor && hasKeyboard)) {
    home.packages = with pkgs; [
      keepassxc
    ];

    xdg.configFile."keepassxc/keepassxc.ini".source = ./keepassxc.ini;
  };
}
