{ selfLib, ... }:

{
  machines.homeModules.pipelines =
    {
      config,
      osConfig,
      lib,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;
    in
    lib.mkIf (hardware.editor || hardware.graphics) {
      dot.processing.pipelines = {
        screenshot-edit = {
          note = "Edit screenshot";
          tags = [
            "screenshot"
            "image"
            "edit"
          ];
          source = selfLib.processing.sources.screenshot;
          sink = selfLib.processing.sinks.image-edit;
        };
        type-speech = {
          note = "Type speech";
          tags = [
            "text"
            "speech"
            "type"
          ];
          source = selfLib.processing.sources.speech-to-text;
          sink = selfLib.processing.sinks.type;
        };
      };
    };
}
