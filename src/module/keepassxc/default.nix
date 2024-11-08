{ pkgs, ... }:

{
  shared = {
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

  home.shared = {
    home.packages = with pkgs; [
      keepassxc
    ];

    xdg.configFile."keepassxc/keepassxc.ini".source = ./keepassxc.ini;
  };
}
