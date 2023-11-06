{ pkgs, config, ... }:

let
  screenshot = pkgs.writeShellApplication {
    name = "screenshot-select";
    runtimeInputs = [ pkgs.grim pkgs.slurp pkgs.tesseract4 pkgs.wl-clipboard ];
    text = ''
      type="png"
      dir="${config.xdg.userDirs.pictures}/screenshots"
      name="$(date -Iseconds)"
      image="$dir/$name.$type"
      text="$dir/$name.txt"
      if [[ ! -d "$dir" ]]
      then
        mkdir -p "$dir"
      fi

      if [[ "$@" == *"--region"* ]]; then
        grim -g "$(slurp)" -t "$type" "$image"
      else
        grim -t "$type" "$image"
      fi

      
      if [[ "$@" == *"--ocr"* ]]; then
        tesseract "$image" "$text"
        wl-copy -t "text/plain" < "$text"
      else
        wl-copy -t "image/$type" < "$image"
      fi
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
      command = "${screenshot}/bin/screenshot --region";
    }
    {
      mods = [ "control" ];
      key = "Print";
      command = "${screenshot}/bin/screenshot --region --ocr";
    }
  ];

  home.packages = with pkgs; [ grim slurp tesseract4 screenshot ];
}
