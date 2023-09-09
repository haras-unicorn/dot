{ pkgs, ... }:

{
  # home.sessionVariables = {
  #   QT_QPA_PLATFORMTHEME = "gtk2";
  # };
  programs.nushell.extraEnv = ''
    $env.QT_QPA_PLATFORMTHEME = "gtk2";
  '';

  qt.enable = true;
  qt.platformTheme = "gtk";
  qt.style.name = "Sweet-Dark";
  qt.style.package = pkgs.sweet;
}
