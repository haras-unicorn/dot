{ pkgs, ... }:

{
  # TODO: systemd
  wayland.windowManager.hyprland.extraConfig = ''
    exec-once = ${pkgs.keepassxc}/bin/keepassxc
  '';

  home.packages = with pkgs; [
    keepassxc
  ];

  xdg.configFile."keepassxc/keepassxc.ini".source = ./keepassxc.ini;
}
