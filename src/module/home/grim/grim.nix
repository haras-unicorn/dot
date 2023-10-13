{ pkgs, config, ... }:

let
  screenshot = pkgs.writeShellApplication {
    name = "screenshot";
    runtimeInputs = [ pkgs.grim pkgs.wl-clipboard ];
    text = ''
      dir="${config.xdg.userDirs.pictures}/screenshots"
      file="$dir/$(date -Iseconds)"
      if [[ ! -d "$dir" ]]
      then
        mkdir -p "$dir"
      fi

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
