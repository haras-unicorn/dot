{ pkgs, ... }:

{
  shared = {
    dot = {
      desktopEnvironment.sessionStartup = [
        "${pkgs.keepassxc}/bin/keepassxc"
      ];
    };
  };

  home.shared = {
    home.packages = with pkgs; [
      keepassxc
    ];

    xdg.configFile."keepassxc/keepassxc.ini".source = ./keepassxc.ini;
  };
}
