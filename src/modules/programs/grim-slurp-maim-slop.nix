{
  self.homeModules.grim-slurp-maim-slop.value =
    {
      pkgs,
      lib,
      config,
      osConfig,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;

      makeScreenshotCommand =
        {
          name,
          command,
          runtimeInputs,
          ...
        }:
        pkgs.writeShellApplication {
          inherit name;
          runtimeInputs = [
            config.dot.commands.copy
            pkgs.libnotify
          ]
          ++ runtimeInputs;
          text = ''
            tmp="$(mktemp -d)"
            mkdir -p "$tmp"
            trap 'rm -rf "$tmp"' EXIT

            type="png"
            name="$(date +${config.dot.desktop.timestamp})"
            ${command}
            copy -t image/$type < "$tmp/$name.$type"
            notify-send --icon="$tmp/$name.$type" Clipboard "copied '$name.$type'" --transient

            dir="${config.dot.desktop.screenshots}"
            mkdir -p "$dir"
            mv "$tmp/$name.$type" "$dir/$name.$type"
          '';
        };

      grimCommand = makeScreenshotCommand {
        name = "screenshot";
        runtimeInputs = [ pkgs.grim ];
        command = ''grim -t "$type" "$tmp/$name.$type"'';
      };

      maimCommand = makeScreenshotCommand {
        name = "screenshot";
        runtimeInputs = [ pkgs.maim ];
        command = ''maim -u "$tmp/$name.$type"'';
      };

      grimSlurpCommand = makeScreenshotCommand {
        name = "regionshot";
        runtimeInputs = [
          pkgs.grim
          pkgs.slurp
        ];
        command = ''grim -g "$(slurp)" -t "$type" "$tmp/$name.$type"'';
      };

      maimSlopCommand = makeScreenshotCommand {
        name = "regionshot";
        runtimeInputs = [
          pkgs.maim
          pkgs.slop
        ];
        command = ''maim -u -g "$(slop -f "%wx%h+%x+%y")" "$tmp/$name.$type"'';
      };
    in
    lib.mkMerge [
      (lib.mkIf (hardware.graphics && hardware.wayland) {
        dot.commands.screenshot = lib.mkDefault grimCommand;
        dot.commands.regionshot = lib.mkIf hardware.typing (lib.mkDefault grimSlurpCommand);

        home.packages = [
          pkgs.grim
          pkgs.slurp
        ];
      })
      (lib.mkIf (hardware.graphics && !hardware.wayland) {
        dot.commands.screenshot = lib.mkDefault maimCommand;
        dot.commands.regionshot = lib.mkIf hardware.pointing (lib.mkDefault maimSlopCommand);

        home.packages = [
          pkgs.maim
          pkgs.slop
        ];
      })
    ];
}
