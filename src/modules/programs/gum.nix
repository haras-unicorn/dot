# TODO: styling via stylix
# theres a lot of environment variables...

{
  machines.homeModules.gum =
    {
      lib,
      osConfig,
      pkgs,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;

      package = pkgs.gum;
    in
    lib.mkIf hardware.editor {
      dot.processing = lib.mkIf (!hardware.graphics) {
        sources = {
          gum = {
            note = "Pick a file";
            tags = [
              "file"
              "picker"
              "load"
              "read"
            ];
            output = "detect";
            package = pkgs.writeShellApplication {
              name = "gum-file-source";
              runtimeInputs = [ package ];
              text = ''
                cat < "$(gum file)"
              '';
            };
          };
        };
        sinks = {
          gum = {
            note = "Save to file";
            tags = [
              "file"
              "picker"
              "save"
              "write"
            ];
            inputs = "any";
            package = pkgs.writeShellApplication {
              name = "gum-file-sink";
              runtimeInputs = [ package ];
              text = ''
                cat > "$(gum input)"
              '';
            };
          };
        };
      };

      home.packages = [
        package
      ];
    };
}
