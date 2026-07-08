{
  machines.homeModules.grim-slurp-maim-slop =
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

      screenshotCommandWayland = makeScreenshotCommand {
        name = "screenshot";
        runtimeInputs = [ pkgs.grim ];
        command = ''grim -t "$type" "$tmp/$name.$type"'';
      };

      screenshotCommandXServer = makeScreenshotCommand {
        name = "screenshot";
        runtimeInputs = [ pkgs.maim ];
        command = ''maim -u "$tmp/$name.$type"'';
      };

      regionshotCommandWayland = makeScreenshotCommand {
        name = "regionshot";
        runtimeInputs = [
          pkgs.grim
          pkgs.slurp
        ];
        command = ''grim -g "$(slurp)" -t "$type" "$tmp/$name.$type"'';
      };

      regionshotCommandXServer = makeScreenshotCommand {
        name = "regionshot";
        runtimeInputs = [
          pkgs.maim
          pkgs.slop
        ];
        command = ''maim -u -g "$(slop -f "%wx%h+%x+%y")" "$tmp/$name.$type"'';
      };

      grim-source = pkgs.writeShellApplication {
        name = "grim-source";
        runtimeInputs = [ pkgs.grim ];
        text = ''grim -t "png" -'';
      };

      maim-source = pkgs.writeShellApplication {
        name = "maim-source";
        runtimeInputs = [ pkgs.maim ];
        text = ''maim -u -f "png"'';
      };

      grim-slurp-source = pkgs.writeShellApplication {
        name = "grim-slurp-source";
        runtimeInputs = [
          pkgs.grim
          pkgs.slurp
        ];
        text = ''grim -g "$(slurp)" -t "png" -'';
      };

      maim-slop-source = pkgs.writeShellApplication {
        name = "maim-slop-source";
        runtimeInputs = [
          pkgs.maim
          pkgs.slop
        ];
        text = ''maim -u -g "$(slop -f "%wx%h+%x+%y")" -f "png"'';
      };
    in
    lib.mkMerge [
      (lib.mkIf (hardware.graphics && hardware.wayland) {
        dot.processing.sources = lib.mkMerge [
          {
            grim = {
              note = "Take a screenshot";
              tags = [
                "image"
                "screenshot"
                "screen"
              ];
              output = "image/png";
              package = grim-source;
            };
          }
          (lib.mkIf hardware.pointing {
            grim-slurp = {
              note = "Take a screenshot of a screen region";
              tags = [
                "image"
                "screenshot"
                "screen"
                "region"
              ];
              output = "image/png";
              package = grim-slurp-source;
            };
          })
        ];

        dot.commands.screenshot = lib.mkDefault screenshotCommandWayland;
        dot.commands.regionshot = lib.mkIf hardware.typing (lib.mkDefault regionshotCommandWayland);

        home.packages = [
          pkgs.grim
          pkgs.slurp
        ];
      })
      (lib.mkIf (hardware.graphics && !hardware.wayland) {
        dot.processing.sources = lib.mkMerge [
          {
            maim = {
              note = "Take a screenshot";
              tags = [
                "image"
                "screenshot"
                "screen"
              ];
              output = "image/png";
              package = maim-source;
            };
          }
          (lib.mkIf hardware.pointing {
            maim-slop = {
              note = "Take a screenshot of a screen region";
              tags = [
                "image"
                "screenshot"
                "screen"
                "region"
              ];
              output = "image/png";
              package = maim-slop-source;
            };
          })
        ];

        dot.commands.screenshot = lib.mkDefault screenshotCommandXServer;
        dot.commands.regionshot = lib.mkIf hardware.pointing (lib.mkDefault regionshotCommandXServer);

        home.packages = [
          pkgs.maim
          pkgs.slop
        ];
      })
    ];
}
