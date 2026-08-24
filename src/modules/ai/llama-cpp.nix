{ self, ... }:

# TODO: try UD models - they might still work with FATE
# TODO: try speculative decoding - this is a perfect scenario for it
# TODO: pick models based on vram somehow??
# NOTE: ubatch ~= in tps, fate cache ~= out tps, ctx size ~= smart

let
  makePackage =
    pkgs:
    let
      cuda = pkgs.config.cudaSupport;

      system = pkgs.stdenv.hostPlatform.system;

      llama-cpp =
        if cuda then
          self.packages.${system}.llama-moe-cache-cuda
        else
          builtins.throw "current llama.cpp version (FATE) doesn't support non-CUDA backends";
    in
    pkgs.buildEnv {
      name = "llama-cpp";
      paths = [ llama-cpp ];
      pathsToLink = [ "/bin" ];
    };

  makeModels = pkgs: {
    gemma-4 = {
      e2b = {
        model = pkgs.fetchurl {
          name = "gemma-4-e2b.gguf";
          url = "https://huggingface.co/unsloth/gemma-4-E2B-it-GGUF/resolve/main/gemma-4-E2B-it-Q4_K_M.gguf";
          hash = "sha256-dAGFsh0izrg6EcOqYq1YQu8yxw9gltdWu+6FoeTsNLg=";

        };
        mmproj = pkgs.fetchurl {
          name = "gemma-4-e2b-mmproj.gguf";
          url = "https://huggingface.co/unsloth/gemma-4-E2B-it-GGUF/resolve/main/mmproj-F16.gguf";
          hash = "sha256-FAvo14SXQfiMUHV9UpuENz7o4nBSzCI2hVtTf0qCFfo=";
        };
      };

      e4b = {
        model = pkgs.fetchurl {
          name = "gemma-4-e4b.gguf";
          url = "https://huggingface.co/unsloth/gemma-4-E4B-it-GGUF/resolve/main/gemma-4-E4B-it-Q4_K_M.gguf";
          hash = "sha256-haiWoEdVPoQvJSl+5bAx1k/zAUfZxK8XseSzlM0fq4c=";
        };

        mmproj = pkgs.fetchurl {
          name = "gemma-4-e4b-mmproj.gguf";
          url = "https://huggingface.co/unsloth/gemma-4-E4B-it-GGUF/resolve/main/mmproj-F16.gguf";
          hash = "sha256-3fRsIdcHjpUzjPwiMGsZsnaimlrQiQI0Sd1U1LYXClE=";
        };
      };

      "26b-a4b" = {
        model = pkgs.fetchurl {
          name = "gemma-4-26b-a4b.gguf";
          url = "https://huggingface.co/bartowski/google_gemma-4-26B-A4B-it-GGUF/resolve/main/google_gemma-4-26B-A4B-it-Q4_K_M.gguf";
          hash = "sha256-oH9yIh6OP3dFWrDX92UtAan2PCYrlUqmkypTJ1oOiVo=";
        };
      };
    };

    qwen-3 = {
      "35b-a3b" = {
        model = pkgs.fetchurl {
          name = "qwen-3-35b-a3b.gguf";
          url = "https://huggingface.co/bartowski/Qwen_Qwen3.6-35B-A3B-GGUF/resolve/main/Qwen_Qwen3.6-35B-A3B-Q4_K_M.gguf";
          hash = "sha256-tG/t0z4L+wyuMIqjwVjQpLLEodIYWh7W8JPNrzkGR3I=";
        };
      };

      "4b" = {
        model = pkgs.fetchurl {
          name = "qwen-3-4b.gguf";
          url = "https://huggingface.co/unsloth/Qwen3.5-4B-GGUF/resolve/main/Qwen3.5-4B-Q4_K_M.gguf";
          hash = "sha256-AP55hv9fa0Y+YkVYIRRgSdtvkxNgOTinCADR+2nvEaQ=";
        };
      };

      embedding = {
        model = pkgs.fetchurl {
          name = "qwen-3-embedding.gguf";
          url = "https://huggingface.co/Qwen/Qwen3-Embedding-0.6B-GGUF/resolve/main/Qwen3-Embedding-0.6B-Q8_0.gguf";
          hash = "sha256-BlB8e0JohGnE5ymLCh4W3v8GyvKRzwpbJ4wwgknD5Dk=";
        };
      };
    };
  };
in
{
  machines.nixosModules.llama-cpp =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    let
      models = makeModels pkgs;
      package = makePackage pkgs;
    in
    lib.mkIf config.nixpkgs.config.cudaSupport {
      environment.systemPackages = [
        package
      ];

      systemd.services.llama-cpp-qwen-3-6-35b-a3b = {
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          ExecStart = builtins.concatStringsSep " " [
            (lib.getExe' package "llama-server")
            "--model"
            models.qwen-3."35b-a3b".model
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
            "--cache-type-k"
            "q8_0"
            "--cache-type-v"
            "q8_0"
            "--ubatch-size"
            "2048"
            "--fate"
            "--fate-cache"
            "4096"
            "--ctx-size"
            "196608"
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

      systemd.services.llama-cpp-gemma-4-e4b = {
        wantedBy = [ "multi-user.target" ];
        environment = {
          CUDA_VISIBLE_DEVICES = "";
        };
        serviceConfig = {
          ExecStart = builtins.concatStringsSep " " [
            (lib.getExe' package "llama-server")
            "--model"
            models.gemma-4.e4b.model
            "--mmproj"
            models.gemma-4.e4b.mmproj
            "--sleep-idle-seconds"
            "900"
            "--host"
            "127.0.0.1"
            "--port"
            "8081"
            "--load-mode"
            "mmap"
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

      systemd.services.llama-cpp-qwen-3-embedding-600M = {
        wantedBy = [ "multi-user.target" ];
        environment = {
          CUDA_VISIBLE_DEVICES = "";
        };
        serviceConfig = {
          ExecStart = builtins.concatStringsSep " " [
            (lib.getExe' package "llama-server")
            "--model"
            models.qwen-3.embedding.model
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

      dot.ai.models = builtins.listToAttrs (
        builtins.concatMap (
          { name, value }:
          let
            family = name;
            models = value;
          in
          builtins.map ({ name, value }: {
            name = "${family}-${name}";
            value = {
              inherit name family;
              files = builtins.attrValues value;
            };
          }) (lib.attrsToList models)
        ) (lib.attrsToList models)
      );

      dot.ai.apis = {
        gpu = {
          url = "http://127.0.0.1:8080/v1";
          model = "qwen-3-35b-a3b";
          context = 196608;
        };
        cpu = {
          url = "http://127.0.0.1:8081/v1";
          vision = true;
          model = "gemma-4-e4b";
          context = 131072;
        };
        embedding = {
          url = "http://127.0.0.1:8082/v1";
          model = "qwen-3-embedding";
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
      models = makeModels pkgs;
      package = makePackage pkgs;

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
          package
        ];
        text = ''
          tmpin="$(mktemp --suffix .png)"
          tmpout="$(mktemp --suffix .txt)"
          trap 'rm -f "$tmpin"; rm -f "$tmpout"' EXIT
          cat > "$tmpin"
          export CUDA_VISIBLE_DEVICES=""
          llama-cli \
            --model ${models.gemma-4.e2b.model} \
            --mmproj ${models.gemma-4.e2b.mmproj} \
            --load-mode mmap \
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
          package
        ];
        text = ''
          tmpin="$(mktemp --suffix .wav)"
          tmpout="$(mktemp --suffix .txt)"
          trap 'rm -f "$tmpin"; rm -f "$tmpout"' EXIT
          cat > "$tmpin"
          export CUDA_VISIBLE_DEVICES=""
          llama-cli \
            --model ${models.gemma-4.e2b.model} \
            --mmproj ${models.gemma-4.e2b.mmproj} \
            --load-mode mmap \
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
          package
        ];
        text = ''
          tmpin="$(mktemp --suffix .txt)"
          tmpout="$(mktemp --suffix .txt)"
          trap 'rm -f "$tmpin"; rm -f "$tmpout"' EXIT
          cat > "$tmpin"
          export CUDA_VISIBLE_DEVICES=""
          llama-cli \
            --model ${models.gemma-4.e2b.model} \
            --mmproj ${models.gemma-4.e2b.mmproj} \
            --load-mode mmap \
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
          package
        ];
        text = ''
          tmpin="$(mktemp --suffix .txt)"
          tmpout="$(mktemp --suffix .txt)"
          trap 'rm -f "$tmpin"; rm -f "$tmpout"' EXIT
          cat > "$tmpin"
          export CUDA_VISIBLE_DEVICES=""
          llama-cli \
            --model ${models.gemma-4.e2b.model} \
            --mmproj ${models.gemma-4.e2b.mmproj} \
            --load-mode mmap \
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
    lib.mkIf config.nixpkgs.config.cudaSupport {
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
    };
}
