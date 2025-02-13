{ self, nix-comfyui, pkgs, config, lib, ... }:

# TODO: listen command with openai-whisper-cpp

let
  packageName =
    if builtins.hasAttr "cudaSupport" config.nixpkgs.config then
      "cuda-comfyui-with-extensions"
    else if builtins.hasAttr "rocmSupport" config.nixpkgs.config then
      "rocm-comfyui-with-extensions"
    else
      null;

  hasAnyPlatform =
    if config.nixpkgs.config.cudaSupport then
      true
    else if config.nixpkgs.config.rocmSupport then
      true
    else
      false;

  hasMonitor = config.dot.hardware.monitor.enable;

  hasKeyboard = config.dot.hardware.keyboard.enable;

  hasSound = config.dot.hardware.sound.enable;

  chromium = self.lib.chromium.wrap pkgs pkgs.ungoogled-chromium "chromium";

  comfyuiPackage = nix-comfyui.packages.${pkgs.system}.${packageName};

  ollamaPackage = config.unstablePkgs.ollama;

  openWebuiPackage = config.unstablePkgs.open-webui;

  comfyui = pkgs.writeShellApplication {
    name = "comfyui";
    runtimeInputs = [ comfyuiPackage ];
    text = ''
      mkdir -p "${config.xdg.dataHome}/comfyui/personal"
      cd "${config.xdg.dataHome}/comfyui/personal"
      comfyui "$@"
    '';
  };

  comfyuiAlternative = pkgs.writeShellApplication {
    name = "comfyui-alternative";
    runtimeInputs = [ comfyuiPackage ];
    text = ''
      mkdir -p "${config.xdg.dataHome}/comfyui/alternative"
      cd "${config.xdg.dataHome}/comfyui/alternative"
      comfyui "$@"
    '';
  };

  ollama = pkgs.writeShellApplication {
    name = "ollama";
    runtimeInputs = [ ollamaPackage ];
    text = ''
      mkdir -p "${config.xdg.dataHome}/ollama/personal"
      cd "${config.xdg.dataHome}/ollama/personal"
      export HOME="${config.xdg.dataHome}/ollama/personal"
      ollama "$@"
    '';
  };

  ollamaAlternative = pkgs.writeShellApplication {
    name = "ollama-alternative";
    runtimeInputs = [ ollamaPackage ];
    text = ''
      mkdir -p "${config.xdg.dataHome}/ollama/alternative"
      cd "${config.xdg.dataHome}/ollama/alternative"
      export HOME="${config.xdg.dataHome}/ollama/alternative"
      ollama "$@"
    '';
  };

  openWebui = pkgs.writeShellApplication {
    name = "open-webui";
    runtimeInputs = [ openWebuiPackage ];
    text = ''
      mkdir -p "${config.xdg.dataHome}/ollama/personal/ui"
      cd "${config.xdg.dataHome}/ollama/personal/ui"
      export STATIC_DIR="${config.xdg.dataHome}/ollama/personal/ui"
      export DATA_DIR="${config.xdg.dataHome}/ollama/personal/ui"
      export HF_HOME="${config.xdg.dataHome}/ollama/personal/ui"
      export SENTENCE_TRANSFORMERS_HOME="${config.xdg.dataHome}/ollama/personal/ui"
      export ENV=prod
      open-webui "$@"
    '';
  };

  openWebuiAlternative = pkgs.writeShellApplication {
    name = "open-webui-alternative";
    runtimeInputs = [ openWebuiPackage ];
    text = ''
      mkdir -p "${config.xdg.dataHome}/ollama/alternative/ui"
      cd "${config.xdg.dataHome}/ollama/alternative/ui"
      export STATIC_DIR="${config.xdg.dataHome}/ollama/alternative/ui"
      export DATA_DIR="${config.xdg.dataHome}/ollama/alternative/ui"
      export HF_HOME="${config.xdg.dataHome}/ollama/alternative/ui"
      export SENTENCE_TRANSFORMERS_HOME="${config.xdg.dataHome}/ollama/alternative/ui"
      export ENV=prod
      open-webui "$@"
    '';
  };

  speak = pkgs.writeShellApplication {
    name = "speak";
    runtimeInputs = [ pkgs.piper-tts pkgs.jq pkgs.alsa-utils ];
    text = ''
      config=""
      command="piper --output-raw --quiet"
      while IFS= read -r line; do
        command+=" $line"

        if [[ "$line" == --config* ]]; then
          config="''${line#--config }"
        fi
      done < "${config.xdg.dataHome}/piper/speak.options"

      if [[ ! -f "$config" ]]; then 
        printf "The options file doesn't contain a valid config parameter.\n"
        exit 1
      fi

      samplerate="$(jq .audio.sample_rate < "$config")"
      if [[ ! $samplerate =~ ^[0-9]+$ ]]; then
        printf "The provided model config does not include a sample rate.\n"
        exit 1
      fi

      cat | \
        sh -c "$command 2>/dev/null" | \
        aplay --rate "$samplerate" --format S16_LE --file-type raw --quiet 2>/dev/null
    '';
  };

  read = pkgs.writeShellApplication {
    name = "read";
    runtimeInputs = [
      speak
      (if config.dot.hardware.graphics.wayland
      then pkgs.wl-clipboard
      else pkgs.xclip)
    ];
    text = ''
      ${if config.dot.hardware.graphics.wayland
      then "wl-paste"
      else "xclip -o"} | speak
    '';
  };

  serverClientApp =
    { name
    , servers
    , waits
    , speed ? 1
    , client
    , runtimeInputs ? [ ]
    , ...
    }@args: pkgs.writeShellApplication
      ((builtins.removeAttrs args [ "servers" "waits" "speed" "client" ]) // (
        let
          ports = builtins.concatStringsSep
            "\n"
            (builtins.genList
              (num: ''
                port${builtins.toString num}=$(shuf -i 32768-65535 -n 1)
                while ss -tulwn | grep -q ":$port${builtins.toString num} "; do
                  port${builtins.toString num}=$(shuf -i 32768-65535 -n 1)
                done
              '')
              (builtins.length servers));

          scope = builtins.concatStringsSep
            " & "
            servers;

          wait = builtins.concatStringsSep
            " && "
            (builtins.map
              (x: "${x} > /dev/null")
              waits);
        in
        {
          runtimeInputs = runtimeInputs ++ [ pkgs.zenity ];
          text = ''
            ${ports}

            systemd-run \
              --user \
              --scope \
              --unit=${name}-servers \
              sh -c "${scope} & wait" &

            echo "Waiting for the ${name} servers to start..."
            (
              progress=0
              while ! (${wait}); do
                sleep ${builtins.toString speed}
                progress=$(( (progress + 100) / 2 ))
                [ $progress -ge 99 ] && progress=99
                echo "$progress"
              done
              echo 100
            ) | zenity \
              --progress \
              --no-cancel \
              --auto-close \
              --title="Starting ${name}" \
              --text="Initializing server..."

            ${client}

            systemctl stop --user ${name}-servers.scope
          '';
        }
      ));

  comfyuiApp = serverClientApp {
    name = "comfyui-app";
    runtimeInputs = [ comfyui chromium ];
    servers = [ "comfyui --preview-method taesd --port $port0" ];
    waits = [ ''curl -s "http://localhost:$port0"'' ];
    client = ''
      chromium \
        "--user-data-dir=${config.xdg.dataHome}/comfyui/personal/session" \
        "--app=http://localhost:$port0"
    '';
  };

  comfyuiAlternativeApp = serverClientApp {
    name = "comfyui-alternative-app";
    runtimeInputs = [ comfyuiAlternative chromium ];
    servers = [ "comfyui-alternative --preview-method taesd --port $port0" ];
    waits = [ ''curl -s "http://localhost:$port0"'' ];
    client = ''
      chromium \
        "--user-data-dir=${config.xdg.dataHome}/comfyui/alternative/session" \
        "--app=http://localhost:$port0"
    '';
  };

  ollamaApp = serverClientApp {
    name = "ollama-app";
    runtimeInputs = [
      ollama
      openWebui
      chromium
    ];
    servers = [
      "env OLLAMA_HOST=http://127.0.0.1:$port0 ollama serve"
      "env OLLAMA_BASE_URL=http://127.0.0.1:$port0 WEBUI_AUTH=False open-webui serve --host 127.0.0.1 --port $port1"
    ];
    waits = [
      ''curl -s "http://localhost:$port0"''
      ''curl -s "http://localhost:$port1"''
    ];
    client = ''
      chromium \
        "--user-data-dir=${config.xdg.dataHome}/ollama/personal/session" \
        "--app=http://localhost:$port1"
    '';
  };

  ollamaAlternativeApp = serverClientApp {
    name = "ollama-alternative-app";
    runtimeInputs = [
      ollamaAlternative
      openWebuiAlternative
      chromium
    ];
    servers = [
      "env OLLAMA_HOST=http://127.0.0.1:$port0 ollama-alternative serve"
      "env OLLAMA_BASE_URL=http://127.0.0.1:$port0 WEBUI_AUTH=False open-webui-alternative serve --host 127.0.0.1 --port $port1"
    ];
    waits = [
      ''curl -s "http://localhost:$port0"''
      ''curl -s "http://localhost:$port1"''
    ];
    client = ''
      chromium \
        "--user-data-dir=${config.xdg.dataHome}/ollama/alternative/session" \
        "--app=http://localhost:$port1"
    '';
  };
in
{
  config = {
    desktopEnvironment.keybinds = lib.mkIf (hasMonitor && hasKeyboard) [
      {
        mods = [ "super" ];
        key = "s";
        command = "${read}/bin/read";
      }
    ];
  };

  home = {
    home.packages = (lib.optionals hasAnyPlatform [
      comfyui
      comfyuiAlternative
      ollama
      ollamaAlternative
      openWebui
      openWebuiAlternative
    ]) ++ (lib.optionals (hasAnyPlatform && hasSound) [
      pkgs.tts
    ]) ++ (lib.optionals (hasAnyPlatform && hasMonitor) [
      comfyuiApp
      comfyuiAlternativeApp
      ollamaApp
      ollamaAlternativeApp
    ]) ++ (lib.optionals hasSound [
      speak
      pkgs.openai-whisper-cpp
    ]);

    xdg.desktopEntries = lib.mkIf (hasAnyPlatform && hasMonitor) {
      comfyui = {
        name = "ComfyUI";
        exec = "${comfyuiApp}/bin/comfyui-app";
        terminal = false;
      };
      ollama = {
        name = "Ollama";
        exec = "${ollamaApp}/bin/ollama-app";
        terminal = false;
      };
    };
  };
}
