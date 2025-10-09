{ pkgs, config, ... }:

let
  transcribe = pkgs.writeShellApplication {
    name = "transcribe";
    runtimeInputs = [
      config.dot.shell.paste
      config.dot.shell.copy
      pkgs.coreutils
      pkgs.tesseract
      pkgs.libnotify
    ];
    text = ''
      text="$(paste | tesseract --psm 1 --oem 1 stdin stdout)"
      trimmed="$(sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' < "$text")";
      echo "$trimmed" | copy
      notify-send Clipboard "copied '$trimmed'" --transient
    '';
  };
in
{
  branch.homeManagerModule.homeManagerModule = {
    dot.desktopEnvironment.keybinds = [
      {
        mods = [ "super" ];
        key = "o";
        command = "${transcribe}/bin/transcribe";
      }
    ];

    home.packages = [
      pkgs.tesseract
      transcribe
    ];
  };
}
