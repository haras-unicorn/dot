{ selfLib, ... }:

{
  machines.homeModules.footage =
    {
      osConfig,
      lib,
      pkgs,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;

      package = pkgs.symlinkJoin {
        name = "footage";
        paths = [ pkgs.footage ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/footage \
            --prefix PATH : "${pkgs.lib.makeBinPath [ pkgs.ffmpeg ]}"
        '';
      };

      sink = pkgs.writeShellApplication {
        name = "footage-sink-edit";
        runtimeInputs = [ package ];
        text = ''
          tmp="$(mktemp -p /tmp "XXXXXXXX.$DOT_TOOLBELT_EXTENSION")"
          trap 'rm -f "$tmp"' EXIT
          cat > "$tmp"
          footage "$tmp" &>/dev/null
        '';
      };
    in
    lib.mkIf hardware.browser {
      dot.processing.sinks.footage-edit = {
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
