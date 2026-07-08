{ inputs, ... }:

{
  machines.nixosModules.sound =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      user = config.dot.user.user;

      hardware = config.dot.hardware;
    in
    {
      imports = [ inputs.musnix.nixosModules.musnix ];

      options.dot = {
        sound = {
          pipewire = lib.mkOption {
            type = lib.types.package;
            internal = true;
          };
        };
      };

      config = lib.mkIf hardware.sound {
        dot.sound.pipewire = config.services.pipewire.package;

        services.pulseaudio.package = pkgs.pulseaudioFull;

        services.pipewire.enable = true;
        services.pipewire.wireplumber.enable = true;
        services.pipewire.alsa.enable = true;
        services.pipewire.alsa.support32Bit = true;
        services.pipewire.jack.enable = true;
        services.pipewire.pulse.enable = true;

        users.users.${user}.extraGroups = [
          "audio"
        ];

        security.rtkit.enable = lib.mkIf (!hardware.battery) true;
        musnix.enable = lib.mkIf (!hardware.battery) true;
      };
    };

  machines.homeModules.sound =
    {
      pkgs,
      lib,
      osConfig,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;

      package = osConfig.dot.sound.pipewire;
    in
    lib.mkIf hardware.sound {
      dot.processing = {
        sinks = {
          pipewire = {
            note = "Play audio on the default output audio interface.";
            tags = [
              "play"
              "audio"
              "interface"
              "speakers"
              "headphones"
            ];
            inputs = [ "audio/x-wav" ];
            package = pkgs.writeShellApplication {
              name = "pipewire-sink-play";
              runtimeInputs = [ package ];
              text = ''
                cat > pw-play -
              '';
            };
          };
        };
        sources = {
          pipewire = {
            note = "Record audio on the default input audio interface or easyeffects source if present.";
            tags = [
              "record"
              "audio"
              "interface"
              "microphone"
            ];
            output = "audio/x-wav";
            package =
              let
                easyeffectsSource = "easyeffects_source";

                jqEasyeffectsSelector = ''
                  [.[]
                    | select(
                        .type == "PipeWire:Interface:Node"
                        and .info.props["node.name"]
                        == "${easyeffectsSource}"
                      )
                  ]
                  | length
                '';

                zenityCheck = ''
                  zenity \
                    --question \
                    --title="Recording..." \
                    --text="Pressing yes saves the recording and pressing no cancels it." \
                '';

                gumCheck = ''
                  gum \
                    confirm \
                    "Recording..." \
                    --affirmative="Stop" \
                    --negative="Cancel" \
                '';

                # NOTE: just as a safety measure
                # 48000 * 60 * 60
                hourSamples = "172800000";
              in
              pkgs.writeShellApplication {
                name = "pipewire-source-record";
                runtimeInputs = [
                  package
                  (if hardware.graphics then pkgs.zenity else pkgs.gum)
                  pkgs.jq
                ];
                text = ''
                  tmp="$(mktemp)"
                  trap 'rm -f "$tmp"' EXIT

                  if [ "$(pw-dump \
                    | jq -e ${lib.escapeShellArg jqEasyeffectsSelector})" \
                    -eq 1 ]; then
                    pw-record \
                      --sample-count ${hourSamples} \
                      --target ${lib.escapeShellArg easyeffectsSource} \
                      "$tmp" \
                      2>/dev/null \
                      &
                  else
                    pw-record \
                      --sample-count ${hourSamples} \
                      "$tmp" \
                      2>/dev/null \
                      &
                  fi
                  pid=$!

                  if ${if hardware.graphics then zenityCheck else gumCheck} 2>/dev/null; then
                    kill "$pid" 2>/dev/null || true
                    wait "$pid" 2>/dev/null || true
                    cat "$tmp"
                  else
                    kill "$pid" 2>/dev/null || true
                    wait "$pid" 2>/dev/null || true
                    exit 1
                  fi
                '';
              };
          };
        };
      };

      dot.desktop.volume = lib.mkMerge [
        (lib.mkIf hardware.browser (lib.getExe pkgs.pwvucontrol))
        (lib.mkIf (!hardware.browser && hardware.editor) (lib.getExe pkgs.wiremix))
      ];

      dot.desktop.windowrules = [
        {
          rule = "float";
          selector = "class";
          arg = "com.saivert.pwvucontrol";
        }
      ];

      home.packages = lib.mkMerge [
        (lib.mkIf hardware.browser [
          pkgs.pwvucontrol
          pkgs.crosspipe
        ])
        (lib.mkIf (!hardware.browser && hardware.editor) [
          pkgs.wiremix
        ])
      ];
    };
}
