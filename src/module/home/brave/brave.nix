{ pkgs, ... }:

{
  home.packages = with pkgs; [
    brave
  ];

  # home.sessionVariables = {
  #   BROWSER = "brave";
  # };
  programs.nushell.extraEnv = ''
    $env.BROWSER = "brave";
  '';
}
