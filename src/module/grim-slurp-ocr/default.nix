{ pkgs, config, ... }:

let
  screenshot = pkgs.writeShellApplication {
    name = "screenshot";
    runtimeInputs = [ pkgs.grim pkgs.slurp pkgs.tesseract pkgs.wl-clipboard ];
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

      # shellcheck disable=SC2199
      if [[ "$@" == *"--region"* ]]; then
        grim -g "$(slurp)" -t "$type" "$image"
      else
        grim -t "$type" "$image"
      fi

      # shellcheck disable=SC2199
      if [[ "$@" == *"--ocr"* ]]; then
        # NOTE: tesseract adds the .txt extension
        tesseract --psm 1 --oem 1 "$image" "$dir/$name"
        trimmed="$(sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' < "$text")";
        echo "$trimmed" | wl-copy -t "text/plain"
        notify-send CHOMP! "copied '$trimmed' to clipboard" --transient
      else
        wl-copy -t "image/$type" < "$image"
        notify-send --icon="$image" CHOMP! "copied '$image' to clipboard" --transient
      fi
    '';
  };
in
{
  shared = {
    dot = {
      desktopEnvironment.keybinds = [
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
    };
  };

  home = {
    home.packages = with pkgs; [ grim slurp tesseract screenshot ];
  };
}
