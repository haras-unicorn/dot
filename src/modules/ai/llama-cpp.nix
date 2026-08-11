{ self, inputs, ... }:

{
  perSystem =
    { pkgs, ... }:
    let
      system = pkgs.stdenv.hostPlatform.system;

      makePackage =
        {
          config ? { },
          override ? { },
        }:
        let
          pkgs = import inputs.nixpkgs {
            inherit system;
            config = {
              allowUnfree = true;
            }
            // config;
          };

          src = pkgs.fetchFromGitHub {
            owner = "ongunm";
            repo = "llama-moe-cache";
            rev = "77c8767d26bd6285b2fe351c58143ee4d6b72fa6";
            hash = "sha256-5sAd5aSmC926ND1IZY5FtkAjRcJCvSzlJHTXJk+jjj8=";
          };

          scope = pkgs.callPackage "${src}/.devops/nix/scope.nix" { };
        in
        scope.llama-cpp.override override;
    in
    {
      packages = {
        llama-moe-cache = makePackage { };
        llama-moe-cache-cuda = makePackage {
          config = {
            cudaSupport = true;
          };
        };
        llama-moe-cache-rocm = makePackage {
          config = {
            rocmSupport = true;
          };
        };
        llama-moe-cache-vulkan = makePackage {
          override = {
            useVulkan = true;
          };
        };
      };
    };

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
          self.packages.${system}.llama-moe-cache-vulkan;

      # NOTE: like this because some libs
      # otherwise conflict with other packages
      package = pkgs.buildEnv {
        name = "llama-cpp";
        paths = [ llama-cpp ];
        pathsToLink = [ "/bin" ];
      };

      # NOTE: don't use UD with FATE - it doesn't account for it

      gemma-4-e2b = pkgs.fetchurl {
        name = "gemma-4-e2b.gguf";
        url = "https://huggingface.co/unsloth/gemma-4-E2B-it-GGUF/resolve/main/gemma-4-E2B-it-Q4_K_M.gguf";
        hash = "sha256-k3i8RxcQIp7xZXCbYuNL+2IjFCDdr21ynnJzBbW4Zy0=";
      };

      gemma-4-e2b-mmproj = pkgs.fetchurl {
        name = "gemma-4-e2b-mmproj.gguf";
        url = "https://huggingface.co/unsloth/gemma-4-E2B-it-GGUF/resolve/main/mmproj-F16.gguf";
        hash = "sha256-FAvo14SXQfiMUHV9UpuENz7o4nBSzCI2hVtTf0qCFfo=";
      };

      gemma-4-26b-a4b = pkgs.fetchurl {
        name = "gemma-4-26b-a4b.gguf";
        url = "https://huggingface.co/bartowski/google_gemma-4-26B-A4B-it-GGUF/resolve/main/google_gemma-4-26B-A4B-it-Q4_K_M.gguf";
        hash = "sha256-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX=";
      };

      gemma-4-e4b = pkgs.fetchurl {
        name = "gemma-4-e4b.gguf";
        url = "https://huggingface.co/unsloth/gemma-4-E4B-it-GGUF/resolve/main/gemma-4-E4B-it-Q4_K_M.gguf";
        hash = "sha256-haiWoEdVPoQvJSl+5bAx1k/zAUfZxK8XseSzlM0fq4c=";
      };

      qwen-3-6-35b-a3b = pkgs.fetchurl {
        name = "qwen-3-6-35b-a3b.gguf";
        url = "https://huggingface.co/bartowski/Qwen_Qwen3.6-35B-A3B-GGUF/resolve/main/Qwen_Qwen3.6-35B-A3B-Q4_K_M.gguf";
        hash = "sha256-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX=";
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

      serverModels = pkgs.linkFarm "llama-cpp-server-models" (
        builtins.map
          (model: {
            name = model.name;
            path = model;
          })
          [
            qwen-3-6-35b-a3b
            qwen-3-5-4b
          ]
      );

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
            --model ${gemma-4-e2b} \
            --mmproj ${gemma-4-e2b-mmproj} \
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
            --model ${gemma-4-e2b} \
            --mmproj ${gemma-4-e2b-mmproj} \
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
            --model ${gemma-4-e2b} \
            --mmproj ${gemma-4-e2b-mmproj} \
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
            --model ${gemma-4-e2b} \
            --mmproj ${gemma-4-e2b-mmproj} \
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

      systemd.user.services.llama-cpp = {
        Install = {
          WantedBy = [ "default.target" ];
        };
        Unit = {
          Description = "llama.cpp router (Qwen3.6-35B-A3B + Qwen3.5-4B)";
          Documentation = "https://github.com/ggml-org/llama.cpp/tree/master/tools/server";
        };
        Service = {
          ExecStart = builtins.concatStringsSep " " [
            (lib.getExe' package "llama-server")
            "--models-dir"
            serverModels
            "--models-max"
            "2"
            "--sleep-idle-seconds"
            "900"
            "--host"
            "127.0.0.1"
            "--port"
            "8080"
            "--flash-attn"
            "on"
            "--gpu-layers"
            "all"
            "--fate"
            "--fate-cache"
            "4096"
            "--cache-type-k"
            "q8_0"
            "--cache-type-v"
            "q8_0"
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

      systemd.user.services.llama-cpp-embeddings = {
        Install = {
          WantedBy = [ "default.target" ];
        };
        Unit = {
          Description = "llama.cpp embedding server (Qwen3-Embedding-0.6B)";
          Documentation = "https://github.com/ggml-org/llama.cpp/tree/master/tools/server";
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
            "8081"
            "--flash-attn"
            "on"
            "--gpu-layers"
            "all"
            "--cache-type-k"
            "q8_0"
            "--cache-type-v"
            "q8_0"
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
