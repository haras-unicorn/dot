{ nix-comfyui, pkgs, config, lib, ... }:

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

  package = nix-comfyui.packages.${pkgs.system}.${packageName};

  comfyui = pkgs.writeShellApplication {
    name = "comfyui";
    runtimeInputs = [ package ];
    text = ''
      mkdir -p "${config.xdg.dataHome}/comfyui"
      cd "${config.xdg.dataHome}/comfyui"
      comfyui --preview-method taesd "$@"
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

  system = {
    networking.firewall.allowedTCPPorts = [
      # comfyui
      8188
    ];
  };

  home = {
    home.packages = lib.optionals hasAnyPlatform [
      comfyui
    ] ++ lib.optionals hasMonitor [
      pkgs.gpt4all
    ] ++ lib.optionals hasSound [
      pkgs.piper-tts
      pkgs.openai-whisper-cpp
      speak
    ];
  };
}
