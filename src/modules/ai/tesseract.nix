{
  machines.homeModules.tesseract =
    { pkgs, config, ... }:
    let
      transcribe = pkgs.writeShellApplication {
        name = "transcribe";
        runtimeInputs = [
          config.dot.programs.shell.paste
          config.dot.programs.shell.copy
          pkgs.coreutils
          pkgs.tesseract
          pkgs.libnotify
        ];
        text = ''
          text="$(paste -t image/png | tesseract --psm 1 --oem 1 stdin stdout)"
          trimmed="$(echo "$text" | xargs)"
          echo "$trimmed" | copy
          notify-send Clipboard "copied '$trimmed'" --transient
        '';
      };
    in
    {
      dot.desktop.keybinds = [
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
