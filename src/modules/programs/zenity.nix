{
  machines.homeModules.zenity =
    {
      lib,
      osConfig,
      pkgs,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;

      package = pkgs.zenity;
    in
    lib.mkIf hardware.graphics {
      dot.processing = {
        sources = {
          zenity = {
            note = "Pick a file";
            tags = [
              "file"
              "picker"
              "load"
              "read"
            ];
            output = "detect";
            package = pkgs.writeShellApplication {
              name = "zenity-file-source";
              runtimeInputs = [ package ];
              text = ''
                cat < "$(zenity --file-selection)"
              '';
            };
          };
        };
        sinks = {
          zenity = {
            note = "Save to file";
            tags = [
              "file"
              "picker"
              "save"
              "write"
            ];
            inputs = "any";
            package = pkgs.writeShellApplication {
              name = "zenity-file-sink";
              runtimeInputs = [ package ];
              text = ''
                cat > "$(zenity --file-selection --save)"
              '';
            };
          };
        };
      };

      dot.desktop.windowrules = [
        {
          rule = "float";
          selector = "class";
          arg = "zenity";
        }
      ];

      home.packages = [
        package
      ];
    };
}
