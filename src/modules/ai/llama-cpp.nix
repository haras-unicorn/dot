{
  machines.homeModules.llama-cpp =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    let
      cuda = config.nixpkgs.config.cudaSupport;

      # NOTE: like this because some libs
      # otherwise conflict with other packages
      package = pkgs.buildEnv {
        name = "llama-cpp";
        paths = [ pkgs.llama-cpp ];
        pathsToLink = [ "/bin" ];
      };

      model = pkgs.fetchurl {
        url = "https://huggingface.co/unsloth/gemma-4-E2B-it-GGUF/resolve/main/gemma-4-E2B-it-Q4_K_M.gguf";
        hash = "sha256-k3i8RxcQIp7xZXCbYuNL+2IjFCDdr21ynnJzBbW4Zy0=";
      };

      mmproj = pkgs.fetchurl {
        url = "https://huggingface.co/unsloth/gemma-4-E2B-it-GGUF/resolve/main/mmproj-F16.gguf";
        hash = "sha256-FAvo14SXQfiMUHV9UpuENz7o4nBSzCI2hVtTf0qCFfo=";
      };

      imagePrompt = ''
        You are an image captioner.
        You only include the image caption in your output (e.g. a cat wearing a hat).
      '';

      audioPrompt = ''
        You are an audio captioner.
        You only include the audio caption in your output (e.g. a cat meowing).
      '';

      textPrompt = ''
        You are a text captioner.
        You only include the text caption in your output (e.g. a poem about cats).
      '';

      generatePrompt = ''
        You are a text generator.
        You only include the generated text in your output.
      '';

      node-describe-image = pkgs.writeShellApplication {
        name = "llama-cpp-node-describe-image";
        runtimeInputs = [
          pkgs.llama-cpp
        ];
        text = ''
          tmpin="$(mktemp --suffix .png)"
          tmpout="$(mktemp --suffix .txt)"
          trap 'rm -f "$tmpin"; rm -f "$tmpout"' EXIT
          cat > "$tmpin"
          llama-cli \
            --model ${model} \
            --mmproj ${mmproj} \
            --mmap \
            --gpu-layers all \
            --flash-attn on \
            --cache-type-k q8_0 \
            --cache-type-v q8_0 \
            --system-prompt ${lib.escapeShellArg imagePrompt} \
            --prompt "Describe this image." \
            --image "$tmpin" \
            --single-turn \
            --no-show-timings \
            --simple-io \
            --log-disable \
            | awk '/^\[End thinking\]$/{flag=1; next} flag && /^Exiting\.\.\.$/{exit} flag' \
            > "$tmpout"
          cat "$tmpout" | sed -z 's/^[[:space:]]*//; s/[[:space:]]*$//'
        '';
      };

      node-describe-audio = pkgs.writeShellApplication {
        name = "llama-cpp-node-describe-audio";
        runtimeInputs = [
          pkgs.llama-cpp
        ];
        text = ''
          tmpin="$(mktemp --suffix .wav)"
          tmpout="$(mktemp --suffix .txt)"
          trap 'rm -f "$tmpin"; rm -f "$tmpout"' EXIT
          cat > "$tmpin"
          llama-cli \
            --model ${model} \
            --mmproj ${mmproj} \
            --mmap \
            --gpu-layers all \
            --flash-attn on \
            --cache-type-k q8_0 \
            --cache-type-v q8_0 \
            --system-prompt ${lib.escapeShellArg audioPrompt} \
            --prompt "Describe this audio." \
            --audio "$tmpin" \
            --single-turn \
            --no-show-timings \
            --simple-io \
            --log-disable \
            | awk '/^\[End thinking\]$/{flag=1; next} flag && /^Exiting\.\.\.$/{exit} flag' \
            > "$tmpout"
          cat "$tmpout" | sed -z 's/^[[:space:]]*//; s/[[:space:]]*$//'
        '';
      };

      node-describe-text = pkgs.writeShellApplication {
        name = "llama-cpp-node-describe-text";
        runtimeInputs = [
          pkgs.llama-cpp
        ];
        text = ''
          tmpin="$(mktemp --suffix .txt)"
          tmpout="$(mktemp --suffix .txt)"
          trap 'rm -f "$tmpin"; rm -f "$tmpout"' EXIT
          cat > "$tmpin"
          llama-cli \
            --model ${model} \
            --mmproj ${mmproj} \
            --mmap \
            --gpu-layers all \
            --flash-attn on \
            --cache-type-k q8_0 \
            --cache-type-v q8_0 \
            --system-prompt ${lib.escapeShellArg textPrompt} \
            --prompt "$(cat "$tmpin")\n\nDescribe the text before this sentence." \
            --single-turn \
            --no-show-timings \
            --simple-io \
            --log-disable \
            | awk '/^\[End thinking\]$/{flag=1; next} flag && /^Exiting\.\.\.$/{exit} flag' \
            > "$tmpout"
          cat "$tmpout" | sed -z 's/^[[:space:]]*//; s/[[:space:]]*$//'
        '';
      };

      node-generate-text = pkgs.writeShellApplication {
        name = "llama-cpp-node-generate-text";
        runtimeInputs = [
          pkgs.llama-cpp
        ];
        text = ''
          tmpin="$(mktemp --suffix .txt)"
          tmpout="$(mktemp --suffix .txt)"
          trap 'rm -f "$tmpin"; rm -f "$tmpout"' EXIT
          cat > "$tmpin"
          llama-cli \
            --model ${model} \
            --mmproj ${mmproj} \
            --mmap \
            --gpu-layers all \
            --flash-attn on \
            --cache-type-k q8_0 \
            --cache-type-v q8_0 \
            --system-prompt ${lib.escapeShellArg generatePrompt} \
            --prompt "$(cat "$tmpin")" \
            --single-turn \
            --no-show-timings \
            --simple-io \
            --log-disable \
            | awk '/^\[End thinking\]$/{flag=1; next} flag && /^Exiting\.\.\.$/{exit} flag' \
            > "$tmpout"
          cat "$tmpout" | sed -z 's/^[[:space:]]*//; s/[[:space:]]*$//'
        '';
      };
    in
    lib.mkIf cuda {
      dot.processing.nodes = {
        llama-cpp-describe-image = {
          note = "Describe an image into text";
          tags = [
            "image"
            "describe"
            "text"
          ];
          inputs = [ "image/png" ];
          output = "text/plain";
          package = node-describe-image;
        };
        llama-cpp-describe-audio = {
          note = "Describe an audio into text";
          tags = [
            "audio"
            "describe"
            "text"
          ];
          inputs = [ "audio/wav" ];
          output = "text/plain";
          package = node-describe-audio;
        };
        llama-cpp-describe-text = {
          note = "Describe text into text";
          tags = [
            "describe"
            "text"
          ];
          inputs = [ "text/plain" ];
          output = "text/plain";
          package = node-describe-text;
        };
        llama-cpp-generate-text = {
          note = "Generate text from text";
          tags = [
            "generate"
            "text"
          ];
          inputs = [ "text/plain" ];
          output = "text/plain";
          package = node-generate-text;
        };
      };

      dot.ai.models.gemma-4.files = [
        model
        mmproj
      ];

      home.packages = [ package ];
    };
}
