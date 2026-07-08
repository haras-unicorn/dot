{
  machines.nixosModules.piper =
    {
      pkgs,
      lib,
      config,
      osConfig,
      ...
    }:
    let
      hardware = config.dot.hardware;

      package = pkgs.piper-tts;

      voicesBaseUrl = "https://huggingface.co/rhasspy/piper-voices/resolve/main";

      makeVoiceBaseUrl =
        voice:
        builtins.concatStringsSep "/" [
          voicesBaseUrl
          voice.language
          voice.dialect
          voice.name
          voice.quality
        ];
      makeVoiceModelFullName = voice: "${voice.dialect}-${voice.name}-${voice.quality}";
      makeVoice =
        voice:
        voice
        // rec {
          full = makeVoiceModelFullName voice;
          url = makeVoiceBaseUrl voice;
          model = pkgs.fetchurl {
            url = "${url}/${full}.onnx";
            sha256 = voice.modelHash;
          };
          config = pkgs.fetchurl {
            url = "${url}/${full}.onnx.json";
            sha256 = voice.configHash;
          };
          sampleRate =
            let
              json = builtins.fromJSON (builtins.readFile config);
            in
            json.audio.sample_rate;
          format = "s16";
          code = builtins.replaceStrings [ "_" ] [ "-" ] voice.dialect;
        };

      voices = {
        amy = makeVoice {
          modelHash = "sha256-pakau33g8QQ1iiWt7UgN2s8f8HYohjJYhuxAai6GqrM=";
          configHash = "sha256-IlCppgW43DWhFnF/rcUFZpXdgJ40oV0C9yoPUtU9Prs=";
          language = "en";
          dialect = "en_US";
          name = "amy";
          quality = "low";
          type = "FEMALE1";
        };
      };
      defaultVoice = voices.amy;

      voiceFormat = pkgs.formats.json { };
      voicesFile = voiceFormat.generate "piper-voices.json" voices;

      node = pkgs.writeScriptBin "piper-tts-processor" ''
        #!${lib.getExe pkgs.nushell} --stdin

        let voices = open '${voicesFile}'

        def "main" [--voice: string] {
          let voice = if $voice == null {
            $voices | get '${defaultVoice.name}'
          } else {
            $voices | get $voice
          }

          ($in
            | ${lib.getExe package}
                --model $voice.model
                --config $voice.config)
        }
      '';

      addVoices = builtins.concatStringsSep "\n" (
        builtins.map (
          {
            code,
            type,
            name,
            ...
          }:
          ''AddVoice "${code}" "${type}" "${name}"''
        ) (builtins.attrValues voices)
      );
    in
    {
      options.dot = {
        piper = {
          node = lib.mkOption {
            type = lib.types.package;
            internal = true;
          };
          sampleRate = lib.mkOption {
            type = lib.types.int;
            internal = true;
          };
        };
      };

      config = lib.mkIf hardware.sound {
        services.speechd.config = ''
          AddModule "piper" "sd_generic" "piper.conf"
        '';

        services.speechd.modules.piper = ''
          GenericExecuteSynth "echo \"$DATA\" | ${lib.getExe node} --voice \"$VOICE\""
          ${addVoices}
          DefaultVoice "${defaultVoice.name}"
        '';

        dot.piper.node = node;
        dot.piper.sampleRate = defaultVoice.sampleRate;

        home-manager.users.${config.dot.user.user}.dot.ai.models.piper.files = builtins.concatMap (
          {
            model,
            config,
            ...
          }:
          [
            model
            config
          ]
        ) (builtins.attrValues voices);

        environment.systemPackages = [
          package
        ];
      };
    };

  machines.homeModules.piper =
    {
      lib,
      osConfig,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;
    in
    lib.mkIf hardware.sound {
      dot.processing.nodes.piper-tts = {
        note = "Turn text into speech";
        tags = [
          "tts"
          "text-to-speech"
          "text"
          "speech"
        ];
        inputs = [ "text/plain" ];
        output = "audio/x-raw; rate=${toString osConfig.dot.piper.sampleRate}; channels=1; format=s16";
        package = osConfig.dot.piper.node;
      };
    };
}
