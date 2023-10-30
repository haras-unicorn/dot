{ pkgs, config, ... }:

let
  screenshot = pkgs.writeShellApplication {
    name = "screenshot";
    runtimeInputs = [ pkgs.grim pkgs.wl-clipboard ];
    text = ''
      type="png"
      dir="${config.xdg.userDirs.pictures}/screenshots"
      file="$dir/$(date -Iseconds).$type"
      if [[ ! -d "$dir" ]]
      then
        mkdir -p "$dir"
      fi

      grim -t "$type" "$file"
      wl-copy -t "image/$type" < "$file"
    '';
  };
in
{
  wayland.windowManager.hyprland.extraConfig = ''
    bind = , Print, exec, ${screenshot}/bin/screenshot
  '';

  home.packages = with pkgs; [ grim screenshot ];
}
