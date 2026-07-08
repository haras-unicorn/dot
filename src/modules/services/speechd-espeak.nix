{
  machines.nixosModules.speechd-espeak =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      hardware = config.dot.hardware;

      espeak = pkgs.symlinkJoin {
        name = "espeak-ng";
        paths = [ pkgs.espeak-ng ];
        postBuild = ''
          rm $out/bin/speak
          rm $out/bin/speak-ng
        '';
      };

      processor = pkgs.writeShellApplication {
        name = "speak";
        runtimeInputs = [
          espeak
          pkgs.alsa-utils
        ];
        text = ''
          cat \
            | espeak-ng \
                --stdin \
                --stdout \
        '';
      };
    in
    {
      options.dot = {
        espeak = {
          processor = lib.mkOption {
            type = lib.types.package;
            internal = true;
          };
        };
      };

      config = lib.mkIf hardware.sound {
        dot.espeak.processor = processor;

        services.speechd.enable = true;

        environment.systemPackages = [ espeak ];
      };
    };

  machines.homeModules.speechd-espeak =
    {
      osConfig,
      lib,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;
    in
    lib.mkIf hardware.sound {
      dot.processing.nodes.espeak = {
        note = "Turn text into speech";
        tags = [
          "tts"
          "text-to-speech"
          "text"
          "speech"
        ];
        inputs = [ "text/plain" ];
        output = "audio/x-wav";
        package = osConfig.dot.espeak.processor;
      };
    };
}
