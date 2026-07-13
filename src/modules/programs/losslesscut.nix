{ selfLib, ... }:

{
  machines.homeModules.losslesscut =
    {
      osConfig,
      lib,
      pkgs,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;

      package = pkgs.losslesscut;

      sink = pkgs.writeShellApplication {
        name = "losslesscut-sink-edit";
        runtimeInputs = [ package ];
        text = ''
          tmp="$(mktemp)"
          trap 'rm -f "$tmp"' EXIT
          cat > "$tmp"
          losslesscut "$tmp" &>/dev/null
        '';
      };
    in
    lib.mkIf hardware.browser {
      dot.processing.sinks.losslesscut-edit = {
        note = "Edit video or audio";
        tags = [
          "editor"
          "video"
          "audio"
        ];
        inputs = selfLib.mime.video ++ selfLib.mime.audio;
        package = sink;
      };

      home.packages = [
        package
      ];
    };
}
