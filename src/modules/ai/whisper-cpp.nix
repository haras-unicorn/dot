{ selfLib, ... }:

let
  makeModels = pkgs: {
    tinyVad = pkgs.fetchurl {
      url = "https://huggingface.co/ggml-org/whisper-vad/resolve/main/ggml-silero-v6.2.0.bin";
      hash = "sha256-KqJpt4XutTqCmDogUB3ffB2cSOM6tjpBORrGyff7aYc=";
    };

    tinyModel = pkgs.fetchurl {
      url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.en.bin";
      hash = "sha256-kh5M+Ghv3Zk9zQgaXaW2w2W/3hFi5ysI11rHUomSCx8=";
    };
  };
in
{
  machines.nixosModules.whisper-cpp =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      cuda = config.nixpkgs.config.cudaSupport;

      models = makeModels pkgs;
    in
    lib.mkIf cuda {
      dot.ai.models.whisper-tiny = {
        name = "tiny";
        family = "whisper";
        files = [
          models.tinyModel
          models.tinyVad
        ];
      };
    };

  machines.homeModules.whisper-cpp =
    {
      pkgs,
      lib,
      config,
      osConfig,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;

      cuda = config.nixpkgs.config.cudaSupport;

      models = makeModels pkgs;

      # NOTE: like this because some libs
      # otherwise conflict with other packages
      package = pkgs.buildEnv {
        name = "whisper-cpp";
        paths = [ pkgs.whisper-cpp ];
        pathsToLink = [ "/bin" ];
      };

      transcribeNode = pkgs.writeShellApplication {
        name = "whisper-cpp-node-transcribe";
        runtimeInputs = [
          package
        ];
        text = ''
          tmpin="$(mktemp --suffix ".$DOT_TOOLBELT_EXTENSION")"
          tmpout="$(mktemp --suffix .txt)"
          trap 'rm -f "$tmpin"; rm -f "$tmpout"' EXIT
          cat > "$tmpin"
          whisper-cli \
            --model ${models.tinyModel} \
            --flash-attn ${if cuda then "on" else "off"} \
            --no-gpu ${if cuda then "off" else "on"} \
            --vad \
            --vad-model "${models.tinyVad}" \
            --no-timestamps \
            --no-prints \
            --output-txt \
            --output-file "''${tmpout%.*}" \
            "$tmpin" \
            1>/dev/null
          cat "$tmpout" | sed -z 's/^[[:space:]]*//; s/[[:space:]]*$//'
        '';
      };

      streamSource =
        let
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
          name = "whisper-stream-source";
          runtimeInputs = [
            package
            (if hardware.graphics then pkgs.zenity else pkgs.gum)
          ];
          text = ''
            whisper-stream \
              --model ${models.tinyModel} \
              ${lib.optionalString cuda "--flash-attn"} \
              ${lib.optionalString (!cuda) "--no-gpu"} \
              --language en \
              2>/dev/null \
              | stdbuf -oL sed 's/\x1b\[[0-9;]*[a-zA-Z]//g' \
              | stdbuf -oL sed '/^\[.*\]$/d' \
              | stdbuf -oL sed 's/^[[:space:]]*//g' \
              | stdbuf -oL sed 's/[[:space:]]*$//g' \
              | stdbuf -oL sed 's/\r//g' \
              | stdbuf -oL tr -s ' ' \
              &
            pid=$!
            trap 'kill -SIGTERM "$pid" 2>/dev/null || true' EXIT

            if ! ${if hardware.graphics then zenityCheck else gumCheck} 2>/dev/null; then
              exit 1
            fi
          '';
        };
    in
    {
      dot.processing.sources.whisper-stream = {
        note = "Real-time speech recognition streaming from microphone";
        tags = [
          "transcription"
          "transcribe"
          "speech"
          "text"
          "stt"
          "speech-to-text"
          "stream"
          "streaming"
        ];
        aliases = [ selfLib.processing.sources.speech-to-text ];
        output = "text/plain";
        package = streamSource;
      };

      dot.processing.nodes.whisper-cpp = {
        note = "Transcribe speech into text";
        tags = [
          "transcription"
          "transcribe"
          "speech"
          "text"
          "stt"
          "speech-to-text"
        ];
        inputs = [
          "audio/wav"
          "audio/x-wav"
          "audio/mpeg"
          "audio/ogg"
          "audio/flac"
        ];
        aliases = [ selfLib.processing.nodes.speech-to-text ];
        output = "text/plain";
        package = transcribeNode;
      };

      home.packages = [
        package
      ];
    };
}
