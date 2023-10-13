{ pkgs, config, ... }:

let
  screenshot = pkgs.writeShellApplication {
    name = "screenshot";
    runtimeInputs = [ pkgs.grim pkgs.wl-clipboard ];
    text = ''
      file="${config.xdg.userDirs.pictures}/screenshots/$(date -Iseconds)"
      grim "$file"
      wl-copy < "$file"
    '';
  };
in
{
  home.packages = with pkgs; [
    grim
    screenshot
  ];

  wayland.windowManager.hyprland.extraConfig = ''
    bind = , Print, exec, ${screenshot}/bin/screenshot
  '';
}
