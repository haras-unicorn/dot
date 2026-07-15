{
  machines.homeModules.whisper-cpp =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cuda = config.nixpkgs.config.cudaSupport;

      # NOTE: like this because some libs
      # otherwise conflict with other packages
      package = pkgs.buildEnv {
        name = "whisper-cpp";
        paths = [ pkgs.whisper-cpp ];
        pathsToLink = [ "/bin" ];
      };

      vad = pkgs.fetchurl {
        url = "https://huggingface.co/ggml-org/whisper-vad/resolve/main/ggml-silero-v6.2.0.bin";
        hash = "sha256-KqJpt4XutTqCmDogUB3ffB2cSOM6tjpBORrGyff7aYc=";
      };

      model = pkgs.fetchurl {
        url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.en.bin";
        hash = "sha256-kh5M+Ghv3Zk9zQgaXaW2w2W/3hFi5ysI11rHUomSCx8=";
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
            --model ${model} \
            --flash-attn ${if cuda then "on" else "off"} \
            --no-gpu ${if cuda then "off" else "on"} \
            --vad \
            --vad-model "${vad}" \
            --no-timestamps \
            --no-prints \
            --output-txt \
            --output-file "''${tmpout%.*}" \
            "$tmpin" \
            1>/dev/null
          cat "$tmpout" | sed -z 's/^[[:space:]]*//; s/[[:space:]]*$//'
        '';
      };

      streamSource = pkgs.writeShellApplication {
        name = "whisper-stream-source";
        runtimeInputs = [
          package
        ];
        text = ''
          whisper-stream \
            --model ${model} \
            --flash-attn ${if cuda then "on" else "off"} \
            --no-gpu ${if cuda then "off" else "on"} \
            --language en \
            --length ${builtins.toString (1 * 60 * 60 * 1000)} \
            2>/dev/null \
            | sed 's/\\[.*\\]//'
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
        output = "text/plain";
        package = transcribeNode;
      };

      dot.ai.models.whisper.files = [
        model
        vad
      ];

      home.packages = [
        package
      ];
    };
}
