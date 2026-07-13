{ selfLib, ... }:

let
  mime = selfLib.mime.default;
  toolbeltMime = selfLib.mime.toolbelt;

  audioFormat = builtins.replaceStrings [ "audio/" ] [ "" ] mime.audio;
  videoFormat =
    let
      format = builtins.replaceStrings [ "video/" ] [ "" ] mime.video;
    in
    if format == "mkv" then "matroska" else format;
  imageFormat = builtins.replaceStrings [ "image/" ] [ "" ] mime.image;
  textFormat = builtins.replaceStrings [ "text/" ] [ "" ] mime.text;
in
{
  machines.homeModules.ffmpeg =
    {
      lib,
      pkgs,
      ...
    }:
    let
      audio = pkgs.writeShellApplication {
        name = "ffmpeg-audio";
        runtimeInputs = [ pkgs.ffmpeg ];
        text = ''
          if echo "$DOT_TOOLBELT_MIME" | grep -q "^${toolbeltMime.audio}"; then
            rate=$(echo "$DOT_TOOLBELT_MIME" | sed -n 's/.*rate=\([[:digit:]]*\).*/\1/p')
            channels=$(echo "$DOT_TOOLBELT_MIME" | sed -n 's/.*channels=\([[:digit:]]*\).*/\1/p')
            fmt=$(echo "$DOT_TOOLBELT_MIME" | sed -n 's/.*format=\([0-9a-zA-Z\-_]*\).*/\1/p')
            rate=''${rate:-48000}
            channels=''${channels:-2}
            case "$fmt" in
              s16) fmt="s16le" ;;
              s24) fmt="s24le" ;;
              s32) fmt="s32le" ;;
              f32) fmt="f32le" ;;
              *)   fmt=''${fmt:-s16le} ;;
            esac
            ffmpeg -f "$fmt" -ar "$rate" -ac "$channels" -i pipe:0 -f ${audioFormat} pipe:1
          else
            ffmpeg -i pipe:0 -f ${audioFormat} pipe:1
          fi
        '';
      };

      video = pkgs.writeShellApplication {
        name = "ffmpeg-video";
        runtimeInputs = [ pkgs.ffmpeg ];
        text = ''
          ffmpeg -i pipe:0 -f ${videoFormat} pipe:1
        '';
      };

      image = pkgs.writeShellApplication {
        name = "ffmpeg-image";
        runtimeInputs = [ pkgs.ffmpeg ];
        text = ''
          ffmpeg -i pipe:0 -f image2pipe -vcodec ${imageFormat} pipe:1
        '';
      };

      text = pkgs.writeShellApplication {
        name = "ffmpeg-text";
        runtimeInputs = [ ];
        text = ''
          cat
        '';
      };
    in
    {
      dot.processing.nodes = {
        ffmpeg-audio = {
          note = "Convert any audio format to ${audioFormat}";
          tags = [
            "convert"
            "audio"
            audioFormat
            "format"
            "ffmpeg"
          ];
          aliases = [ "audio-${videoFormat}" ];
          inputs = selfLib.mime.audio ++ [ toolbeltMime.audio ];
          output = mime.audio;
          package = audio;
        };

        ffmpeg-video = {
          note = "Convert any video format to ${videoFormat}";
          tags = [
            "convert"
            "video"
            "${videoFormat}"
            "format"
            "ffmpeg"
          ];
          aliases = [ "video-${videoFormat}" ];
          inputs = selfLib.mime.video;
          output = mime.video;
          package = video;
        };

        ffmpeg-image = {
          note = "Convert any image format to ${imageFormat}";
          tags = [
            "convert"
            "image"
            "${imageFormat}"
            "format"
            "ffmpeg"
          ];
          aliases = [ "image-${imageFormat}" ];
          inputs = selfLib.mime.image;
          output = mime.image;
          package = image;
        };

        "text-${textFormat}" = {
          note = "Ensure text data is ${textFormat}";
          tags = [
            "convert"
            "text"
            "${textFormat}"
            "passthrough"
            "id"
            "format"
          ];
          aliases = [
            "passthrough"
            "id"
          ];
          inputs = selfLib.mime.editor;
          output = mime.text;
          package = text;
        };
      };

      home.packages = [ pkgs.ffmpeg ];
    };
}
