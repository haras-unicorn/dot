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

  screenshot-select = pkgs.writeShellApplication {
    name = "screenshot-select";
    runtimeInputs = [ pkgs.grim pkgs.slurp pkgs.wl-clipboard ];
    text = ''
      type="png"
      dir="${config.xdg.userDirs.pictures}/screenshots"
      file="$dir/$(date -Iseconds).$type"
      if [[ ! -d "$dir" ]]
      then
        mkdir -p "$dir"
      fi

      grim -g "$(slurp)" -t "$type" "$file"
      wl-copy -t "image/$type" < "$file"
    '';
  };
in
{
  de.keybinds = [
    {
      mods = [ ];
      key = "Print";
      command = "${screenshot}/bin/screenshot";
    }
    {
      mods = [ "shift" ];
      key = "Print";
      command = "${screenshot-select}/bin/screenshot-select";
    }
  ];

  home.packages = with pkgs; [ grim slurp screenshot screenshot-select ];
}
