{ selfLib, ... }:

{
  machines.homeModules.tenacity =
    {
      osConfig,
      lib,
      pkgs,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;

      package = pkgs.tenacity;

      sink = pkgs.writeShellApplication {
        name = "tenacity-sink-edit";
        runtimeInputs = [ package ];
        text = ''
          tmp="$(mktemp)"
          trap 'rm -f "$tmp"' EXIT
          cat > "$tmp"
          tenacity "$tmp" &>/dev/null
        '';
      };
    in
    lib.mkIf hardware.browser {
      dot.processing.sinks.tenacity-edit = {
        note = "Edit audio";
        tags = [ "audio" ];
        inputs = selfLib.mime.video ++ selfLib.mime.audio;
        package = sink;
      };

      home.packages = [
        package
      ];
    };
}
