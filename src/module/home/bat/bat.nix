{ pkgs, ... }:

{
  programs.bat.enable = true;
  programs.bat.config = { style = "header,rule,snip,changes"; };

  wayland.windowManager.hyprland.extraConfig = ''
    env = PAGER, ${pkgs.bat}/bin/bat
  '';

  programs.nushell.environmentVariables = {
    PAGER = "${pkgs.bat}/bin/bat";
  };
  programs.nushell.shellAliases = {
    cat = "${pkgs.bat}/bin/bat";
  };
}
