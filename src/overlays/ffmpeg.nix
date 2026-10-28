{ self, selfLib, ... }:

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
in
{
  self.overlays.overlays.ffmpeg.value = final: _prev: {
    ffmpeg-audio = final.writeShellApplication {
      name = "ffmpeg-audio";
      runtimeInputs = [ final.ffmpeg ];
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

    ffmpeg-video = final.writeShellApplication {
      name = "ffmpeg-video";
      runtimeInputs = [ final.ffmpeg ];
      text = ''
        ffmpeg -i pipe:0 -f ${videoFormat} pipe:1
      '';
    };

    ffmpeg-image = final.writeShellApplication {
      name = "ffmpeg-image";
      runtimeInputs = [ final.ffmpeg ];
      text = ''
        ffmpeg -i pipe:0 -f image2pipe -vcodec ${imageFormat} pipe:1
      '';
    };

    ffmpeg-pcm = final.writeShellApplication {
      name = "ffmpeg-pcm";
      runtimeInputs = [ final.ffmpeg ];
      text = ''
        ffmpeg -i pipe:0 -f s16le -ar 48000 -ac 2 pipe:1
      '';
    };
  };
}
