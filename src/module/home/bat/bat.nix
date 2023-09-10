{ ... }:

{
  programs.bat.enable = true;
  programs.bat.config = { style = "header,rule,snip,changes"; };

  wayland.windowManager.hyprland.extraConfig = ''
    env = PAGER, bat
  '';

  programs.nushell.extraEnv = ''
    alias cat = bat;
  '';
}
