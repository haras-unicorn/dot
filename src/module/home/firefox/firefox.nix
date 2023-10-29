{ pkgs, ... }:

{
  home.sessionVariables = {
    BROWSER = "${pkgs.firefox-bin}/bin/firefox";
  };

  wayland.windowManager.hyprland.extraConfig = ''
    bind = super, w, exec, ${pkgs.firefox-bin}/bin/firefox
  '';

  programs.firefox.enable = true;
  programs.firefox.package = pkgs.firefox-bin;
}
