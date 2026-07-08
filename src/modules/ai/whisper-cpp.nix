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

      processor = pkgs.writeShellApplication {
        name = "whisper-cpp-node-transcribe";
        runtimeInputs = [
          package
        ];
        text = ''
          tmpin="$(mktemp --suffix .wav)"
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
    in
    {
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
        ];
        output = "text/plain";
        package = processor;
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
