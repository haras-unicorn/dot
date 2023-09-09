{ pkgs, ... }:

{
  programs.regreet.enable = true;
  programs.hyprland.enable = true;
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  environment.systemPackages = with pkgs; [
    gtk3
  ];
}
