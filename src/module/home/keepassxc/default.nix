{ pkgs, ... }:

{
  home.shared = {
    de.sessionStartup = [
      "${pkgs.keepassxc}/bin/keepassxc"
    ];

    home.packages = with pkgs; [
      keepassxc
    ];

    xdg.configFile."keepassxc/keepassxc.ini".source = ./keepassxc.ini;
  };
}
