{ selfLib, ... }:

{
  machines.homeModules.pinta =
    {
      osConfig,
      lib,
      pkgs,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;

      package = pkgs.pinta;

      sink = pkgs.writeShellApplication {
        name = "pinta-sink-edit";
        runtimeInputs = [ package ];
        text = ''
          tmp="$(mktemp)"
          trap 'rm -f "$tmp"' EXIT
          cat > "$tmp"
          pinta "$tmp"
        '';
      };
    in
    lib.mkIf hardware.browser {
      dot.processing.sinks.pinta-edit = {
        note = "Edit an image";
        tags = [
          "editor"
          "image"
        ];
        inputs = selfLib.mime.image;
        package = sink;
      };

      home.packages = [
        package
      ];
    };
}
