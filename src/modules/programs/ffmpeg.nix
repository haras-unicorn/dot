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
  self.homeModules.ffmpeg.value =
    { pkgs, ... }:
    let
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
          package = pkgs.harasPackages.ffmpeg-audio;
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
          package = pkgs.harasPackages.ffmpeg-video;
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
          package = pkgs.harasPackages.ffmpeg-image;
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

        ffmpeg-pcm = {
          note = "Convert any audio format to raw PCM";
          tags = [
            "convert"
            "audio"
            "pcm"
            "raw"
            "ffmpeg"
          ];
          aliases = [ "audio-pcm" ];
          inputs = selfLib.mime.audio;
          output = "${toolbeltMime.audio}; rate=48000; channels=2; format=s16";
          package = pkgs.harasPackages.ffmpeg-pcm;
        };
      };

      home.packages = [ pkgs.ffmpeg ];
    };
}
