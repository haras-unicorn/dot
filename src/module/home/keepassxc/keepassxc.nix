{ pkgs, ... }:

{
  home.packages = with pkgs; [
    keepassxc
  ];

  xdg.configFile."keepassxc/keepassxc.ini".source = ./keepassxc.ini;
}
