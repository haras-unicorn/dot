{
  machines.homeModules.wf-recorder-slurp =
    {
      osConfig,
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cuda = config.nixpkgs.config.cudaSupport;

      codec = if cuda then "hevc_nvenc" else "libx265";

      hardware = osConfig.dot.hardware;

      makeScreenrecordCommand =
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

            type="mp4"
            name="$(date +${config.dot.desktop.timestamp})"
            ${command} -o "$tmp/$name.$type"
            copy -t image/$type < "$tmp/$name.$type"
            notify-send --icon="$tmp/$name.$type" Clipboard "copied '$name.$type'" --transient

            dir="${config.dot.desktop.screenshots}"
            mkdir -p "$dir"
            mv "$tmp/$name.$type" "$dir/$name.$type"
          '';
        };

      screenrecordCommand = makeScreenrecordCommand {
        name = "screenrecord";
        runtimeInputs = [
          wf-recorder
        ];
        command = ''wf-recorder -c "${codec}"'';
      };

      regionrecordCommand = makeScreenrecordCommand {
        name = "regionrecord";
        runtimeInputs = [
          wf-recorder
          slurp
        ];
        command = ''wf-recorder -g "$(slurp)" -c "${codec}"'';
      };

      wf-recorder = pkgs.wf-recorder;

      slurp = pkgs.slurp;

      screenrecordSource = pkgs.writeShellApplication {
        name = "wf-recorder-source";
        runtimeInputs = [
          wf-recorder
        ];
        text = ''
          tmp="$(mktemp)"
          trap 'rm -f "$tmp"' EXIT
          wf-recorder -c ${codec} -o "$tmp" &>/dev/null
          cat "$tmp"
        '';
      };

      regionrecordSource = pkgs.writeShellApplication {
        name = "wf-recorder-slurp-source";
        runtimeInputs = [
          wf-recorder
          slurp
        ];
        text = ''
          tmp="$(mktemp)"
          trap 'rm -f "$tmp"' EXIT
          wf-recorder -g "$(slurp)" -c ${codec} -o "$tmp" &>/dev/null
          cat "$tmp"
        '';
      };
    in
    lib.mkIf (hardware.browser && hardware.wayland) {
      dot.processing.sources = lib.mkMerge [
        {
          wf-recorder = {
            note = "Take a screen recording";
            tags = [
              "image"
              "record"
              "screen"
            ];
            output = "image/png";
            package = screenrecordSource;
          };
        }
        (lib.mkIf hardware.pointing {
          wf-recorder-slurp = {
            note = "Take a screen recording of a screen region";
            tags = [
              "image"
              "record"
              "screen"
              "region"
            ];
            output = "image/png";
            package = regionrecordSource;
          };
        })
      ];

      dot.commands.screenrecord = lib.mkDefault screenrecordCommand;
      dot.commands.regionrecord = lib.mkIf hardware.typing (lib.mkDefault regionrecordCommand);

      home.packages = [
        wf-recorder
      ];
    };
}
