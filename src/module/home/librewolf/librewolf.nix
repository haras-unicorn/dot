{ pkgs, ... }:

# TODO: fix attempting to compile

{
  systemd.user.sessionVariables = {
    BROWSER = "${pkgs.librewolf}/bin/librewolf";
  };

  wayland.windowManager.hyprland.extraConfig = ''
    bind = super, w, exec, ${pkgs.librewolf}/bin/librewolf
  '';

  programs.librewolf.enable = true;
}
