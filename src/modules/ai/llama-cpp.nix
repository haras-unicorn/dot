{ self, ... }:

# TODO: try UD models - they might still work with FATE
# TODO: try speculative decoding - this is a perfect scenario for it
# NOTE: ubatch ~= in tps, fate cache ~= out tps, ctx size ~= smart

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

      system = pkgs.stdenv.hostPlatform.system;

      llama-cpp =
        if cuda then
          self.packages.${system}.llama-moe-cache-cuda
        else
          builtins.throw "current llama.cpp version (FATE) doesn't support non-CUDA backends";

      # NOTE: like this because some libs
      # otherwise conflict with other packages
      package = pkgs.buildEnv {
        name = "llama-cpp";
        paths = [ llama-cpp ];
        pathsToLink = [ "/bin" ];
      };

      gemma-4-e2b = pkgs.fetchurl {
        name = "gemma-4-e2b.gguf";
        url = "https://huggingface.co/unsloth/gemma-4-E2B-it-GGUF/resolve/main/gemma-4-E2B-it-Q4_K_M.gguf";
        hash = "sha256-dAGFsh0izrg6EcOqYq1YQu8yxw9gltdWu+6FoeTsNLg=";
      };

      gemma-4-e2b-mmproj = pkgs.fetchurl {
        name = "gemma-4-e2b-mmproj.gguf";
        url = "https://huggingface.co/unsloth/gemma-4-E2B-it-GGUF/resolve/main/mmproj-F16.gguf";
        hash = "sha256-FAvo14SXQfiMUHV9UpuENz7o4nBSzCI2hVtTf0qCFfo=";
      };

      gemma-4-26b-a4b = pkgs.fetchurl {
        name = "gemma-4-26b-a4b.gguf";
        url = "https://huggingface.co/bartowski/google_gemma-4-26B-A4B-it-GGUF/resolve/main/google_gemma-4-26B-A4B-it-Q4_K_M.gguf";
        hash = "sha256-oH9yIh6OP3dFWrDX92UtAan2PCYrlUqmkypTJ1oOiVo=";
      };

      gemma-4-e4b = pkgs.fetchurl {
        name = "gemma-4-e4b.gguf";
        url = "https://huggingface.co/unsloth/gemma-4-E4B-it-GGUF/resolve/main/gemma-4-E4B-it-Q4_K_M.gguf";
        hash = "sha256-haiWoEdVPoQvJSl+5bAx1k/zAUfZxK8XseSzlM0fq4c=";
      };

      qwen-3-6-35b-a3b = pkgs.fetchurl {
        name = "qwen-3-6-35b-a3b.gguf";
        url = "https://huggingface.co/bartowski/Qwen_Qwen3.6-35B-A3B-GGUF/resolve/main/Qwen_Qwen3.6-35B-A3B-Q4_K_M.gguf";
        hash = "sha256-tG/t0z4L+wyuMIqjwVjQpLLEodIYWh7W8JPNrzkGR3I=";
      };

      qwen-3-5-4b = pkgs.fetchurl {
        name = "qwen-3-5-4b.gguf";
        url = "https://huggingface.co/unsloth/Qwen3.5-4B-GGUF/resolve/main/Qwen3.5-4B-Q4_K_M.gguf";
        hash = "sha256-AP55hv9fa0Y+YkVYIRRgSdtvkxNgOTinCADR+2nvEaQ=";
      };

      qwen-3-embedding = pkgs.fetchurl {
        name = "qwen-3-embedding.gguf";
        url = "https://huggingface.co/Qwen/Qwen3-Embedding-0.6B-GGUF/resolve/main/Qwen3-Embedding-0.6B-Q8_0.gguf";
        hash = "sha256-BlB8e0JohGnE5ymLCh4W3v8GyvKRzwpbJ4wwgknD5Dk=";
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
          llama-cpp
        ];
        text = ''
          tmpin="$(mktemp --suffix .png)"
          tmpout="$(mktemp --suffix .txt)"
          trap 'rm -f "$tmpin"; rm -f "$tmpout"' EXIT
          cat > "$tmpin"
          llama-cli \
            --model ${gemma-4-e2b} \
            --mmproj ${gemma-4-e2b-mmproj} \
            --load-mode mmap \
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
          llama-cpp
        ];
        text = ''
          tmpin="$(mktemp --suffix .wav)"
          tmpout="$(mktemp --suffix .txt)"
          trap 'rm -f "$tmpin"; rm -f "$tmpout"' EXIT
          cat > "$tmpin"
          llama-cli \
            --model ${gemma-4-e2b} \
            --mmproj ${gemma-4-e2b-mmproj} \
            --load-mode mmap \
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
          llama-cpp
        ];
        text = ''
          tmpin="$(mktemp --suffix .txt)"
          tmpout="$(mktemp --suffix .txt)"
          trap 'rm -f "$tmpin"; rm -f "$tmpout"' EXIT
          cat > "$tmpin"
          llama-cli \
            --model ${gemma-4-e2b} \
            --mmproj ${gemma-4-e2b-mmproj} \
            --load-mode mmap \
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
          llama-cpp
        ];
        text = ''
          tmpin="$(mktemp --suffix .txt)"
          tmpout="$(mktemp --suffix .txt)"
          trap 'rm -f "$tmpin"; rm -f "$tmpout"' EXIT
          cat > "$tmpin"
          llama-cli \
            --model ${gemma-4-e2b} \
            --mmproj ${gemma-4-e2b-mmproj} \
            --load-mode mmap \
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
        gemma-4-e2b
        gemma-4-e2b-mmproj
        gemma-4-e4b
        gemma-4-26b-a4b
      ];

      dot.ai.models.qwen-3-5.files = [
        qwen-3-6-35b-a3b
        qwen-3-5-4b
        qwen-3-embedding
      ];

      systemd.user.services.llama-cpp-qwen-3-6-35b-a3b = {
        Install = {
          WantedBy = [ "default.target" ];
        };
        Service = {
          ExecStart = builtins.concatStringsSep " " [
            (lib.getExe' package "llama-server")
            "--model"
            qwen-3-6-35b-a3b
            "--sleep-idle-seconds"
            "900"
            "--host"
            "127.0.0.1"
            "--port"
            "8080"
            "--load-mode"
            "mmap"
            "--flash-attn"
            "on"
            "--gpu-layers"
            "all"
            "--fate"
            "--cache-type-k"
            "q8_0"
            "--cache-type-v"
            "q8_0"
            "--ubatch-size"
            "2048"
            "--fate-cache"
            "4096"
            "--ctx-size"
            "262144"
          ];
          Restart = "on-failure";
          RestartSec = 5;

          ProtectSystem = "strict";
          ProtectHome = "read-only";
          PrivateTmp = true;

          NoNewPrivileges = true;
          LockPersonality = true;

          RestrictAddressFamilies = [
            "AF_INET"
            "AF_INET6"
            "AF_NETLINK"
            "AF_UNIX"
          ];
          IPAddressDeny = "any";
          IPAddressAllow = [
            "127.0.0.0/8"
            "::1"
          ];
        };
      };

      systemd.user.services.llama-cpp-gemma-4-e2b = {
        Install = {
          WantedBy = [ "default.target" ];
        };
        Service = {
          ExecStart = builtins.concatStringsSep " " [
            (lib.getExe' package "llama-server")
            "--model"
            gemma-4-e2b
            "--mmproj"
            gemma-4-e2b-mmproj
            "--sleep-idle-seconds"
            "900"
            "--host"
            "127.0.0.1"
            "--port"
            "8081"
            "--load-mode"
            "mmap"
            "--flash-attn"
            "on"
            "--gpu-layers"
            "0"
            "--cache-type-k"
            "q8_0"
            "--cache-type-v"
            "q8_0"
            "--ubatch-size"
            "2048"
            "--ctx-size"
            "131072"
          ];
          Restart = "on-failure";
          RestartSec = 5;

          ProtectSystem = "strict";
          ProtectHome = "read-only";
          PrivateTmp = true;

          NoNewPrivileges = true;
          LockPersonality = true;

          RestrictAddressFamilies = [
            "AF_INET"
            "AF_INET6"
            "AF_NETLINK"
            "AF_UNIX"
          ];
          IPAddressDeny = "any";
          IPAddressAllow = [
            "127.0.0.0/8"
            "::1"
          ];
        };
      };

      systemd.user.services.llama-cpp-qwen-3-embedding-600M = {
        Install = {
          WantedBy = [ "default.target" ];
        };
        Service = {
          ExecStart = builtins.concatStringsSep " " [
            (lib.getExe' package "llama-server")
            "--model"
            "${qwen-3-embedding}"
            "--embeddings"
            "--pooling"
            "last"
            "--sleep-idle-seconds"
            "900"
            "--host"
            "127.0.0.1"
            "--port"
            "8082"
            "--load-mode"
            "mmap"
            "--gpu-layers"
            "0"
            "--cache-type-k"
            "q8_0"
            "--cache-type-v"
            "q8_0"
            "--ubatch-size"
            "2048"
            "--ctx-size"
            "32768"
          ];
          Restart = "on-failure";
          RestartSec = 5;

          ProtectSystem = "strict";
          ProtectHome = "read-only";
          PrivateTmp = true;

          NoNewPrivileges = true;
          LockPersonality = true;

          RestrictAddressFamilies = [
            "AF_INET"
            "AF_INET6"
            "AF_NETLINK"
            "AF_UNIX"
          ];
          IPAddressDeny = "any";
          IPAddressAllow = [
            "127.0.0.0/8"
            "::1"
          ];
        };
      };

      home.packages = [ package ];
    };
}
