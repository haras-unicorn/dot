{ pkgs, ... }:

# FIXME: codec from hardware

let
  ffmpeg-cut-1080p = pkgs.writeShellApplication {
    name = "ffmpeg-cut-1080p";
    runtimeInputs = [ pkgs.ffmpeg_6-full ];
    text = ''
      ffmpeg \
        -i "$1" \
        -filter:v "crop=1920:1080:(iw-1920)/2:(ih-1080)/2" \
        -ss "$2" \
        -t "$3" \
        -c:v h264_nvenc \
        "$4"
    '';
  };

  ffmpeg-cut-720p = pkgs.writeShellApplication {
    name = "ffmpeg-cut-720p";
    runtimeInputs = [ pkgs.ffmpeg_6-full ];
    text = ''
      ffmpeg \
        -i "$1" \
        -filter:v "crop=1280:720:(iw-1280)/2:(ih-720)/2" \
        -ss "$2" \
        -t "$3" \
        -c:v h264_nvenc \
        "$4"
    '';
  };
in
{
  home = {
    home.packages = with pkgs; [
      ffmpeg-cut-1080p
      ffmpeg-cut-720p
      ffmpeg_6-full
    ];
  };
}
