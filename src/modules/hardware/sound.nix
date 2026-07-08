{ selfLib, inputs, ... }:

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
            inputs = [
              "audio/wav"
              "audio/x-wav"
              selfLib.mime.toolbelt.audio
            ];
            package = pkgs.writeShellApplication {
              name = "pipewire-sink-play";
              runtimeInputs = [ package ];
              text = ''
                if echo "$DOT_TOOLBELT_MIME" | grep -q "^${selfLib.mime.toolbelt.audio}"; then
                  rate=$(echo "$DOT_TOOLBELT_MIME" | sed -n 's/.*rate=\([[:digit:]]*\).*/\1/p')
                  channels=$(echo "$DOT_TOOLBELT_MIME" | sed -n 's/.*channels=\([[:digit:]]*\).*/\1/p')
                  format=$(echo "$DOT_TOOLBELT_MIME" | sed -n 's/.*format=\([a-zA-Z0-9\-_]*\).*/\1/p')
                  rate=''${rate:-48000}
                  channels=''${channels:-2}
                  format=''${format:-s16}
                  pw-play --format "$format" --rate "$rate" --channels "$channels" --format "$format" -
                else
                  cat > pw-play -
                fi
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
            output = "audio/x-raw; rate=48000; channels=2; format=s16";
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
              in
              pkgs.writeShellApplication {
                name = "pipewire-source-record";
                runtimeInputs = [
                  package
                  (if hardware.graphics then pkgs.zenity else pkgs.gum)
                  pkgs.jq
                ];
                text = ''
                  if [ "$(pw-dump \
                    | jq -e ${lib.escapeShellArg jqEasyeffectsSelector})" \
                    -eq 1 ]; then
                    pw-cat \
                      --record \
                      --format s16 \
                      --rate 48000 \
                      --channels 2 \
                      --target ${lib.escapeShellArg easyeffectsSource} \
                      - \
                      2>/dev/null \
                      &
                  else
                    pw-cat \
                      --record \
                      --format s16 \
                      --rate 48000 \
                      --channels 2 \
                      - \
                      2>/dev/null \
                      &
                  fi
                  pid=$!

                  if ${if hardware.graphics then zenityCheck else gumCheck} 2>/dev/null; then
                    kill "$pid" 2>/dev/null || true
                    wait "$pid" 2>/dev/null || true
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
