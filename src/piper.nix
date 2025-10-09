{
  pkgs,
  lib,
  config,
  ...
}:

let
  hasSound = config.dot.hardware.sound.enable;
  hasKeyboard = config.dot.hardware.keyboard.enable;
  hasMonitor = config.dot.hardware.monitor.enable;

  voicesBaseUrl = "https://huggingface.co/rhasspy/piper-voices/resolve/main";
  mkVoiceBaseUrl =
    voice:
    builtins.concatStringsSep "/" [
      voicesBaseUrl
      voice.language
      voice.dialect
      voice.name
      voice.quality
    ];
  mkVoiceModelName = voice: "${voice.dialect}-${voice.name}-${voice.quality}.onnx";
  mkVoiceConfigName = voice: "${voice.dialect}-${voice.name}-${voice.quality}.onnx.json";
  mkVoice =
    voice:
    voice
    // rec {
      model = pkgs.fetchurl {
        url = "${mkVoiceBaseUrl voice}/${mkVoiceModelName voice}";
        sha256 = voice.modelHash;
      };
      config = pkgs.fetchurl {
        url = "${mkVoiceBaseUrl voice}/${mkVoiceConfigName voice}";
        sha256 = voice.configHash;
      };
      sampleRate =
        let
          json = builtins.fromJSON (builtins.readFile config);
        in
        json.audio.sample_rate;
    };

  voices = {
    amy = mkVoice {
      modelHash = "sha256-pakau33g8QQ1iiWt7UgN2s8f8HYohjJYhuxAai6GqrM=";
      configHash = "sha256-IlCppgW43DWhFnF/rcUFZpXdgJ40oV0C9yoPUtU9Prs=";
      language = "en";
      dialect = "en_US";
      name = "amy";
      quality = "low";
    };
  };

  speakVoice = voices.amy;
  speak = pkgs.writeShellApplication {
    name = "speak";
    runtimeInputs = [
      pkgs.piper-tts
      pkgs.alsa-utils
      pkgs.coreutils
    ];
    text = ''
      cat \
        | piper \
            --model ${speakVoice.model} \
            --config ${speakVoice.config} \
            --output-raw \
        | aplay \
            --rate ${builtins.toString speakVoice.sampleRate} \
            --format S16_LE \
            --file-type raw \
            --quiet \
            2>/dev/null
    '';
  };

  read = pkgs.writeShellApplication {
    name = "read";
    runtimeInputs = [
      speak
      config.dot.shell.paste
      pkgs.coreutils
    ];
    text = ''
      paste | speak
    '';
  };
in
{
  branch.homeManagerModule.homeManagerModule = lib.mkIf hasSound {
    home.packages = [
      speak
      pkgs.piper-tts
    ];

    dot.desktopEnvironment.keybinds = lib.mkIf (hasKeyboard && hasMonitor) [
      {
        mods = [ "super" ];
        key = "s";
        command = "${read}/bin/read";
      }
    ];
  };
}
