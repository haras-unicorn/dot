{ pkgs, ... }:

# TODO: codec from hardware

let
  cut-1080p = pkgs.writeShellApplication {
    name = "cut";
    runtimeInputs = [ pkgs.ffmpeg_6-full ];
    text = ''
      ffmpeg \
        -i "$1" \
        -filter:v "crop=1920:1080:(ow-1920)/2:(oh-1080)/2" \
        -ss "$2" \
        -t "$3" \
        -c:v h264_nvenc \
        "$4"
    '';
  };

  cut-720p = pkgs.writeShellApplication {
    name = "cut";
    runtimeInputs = [ pkgs.ffmpeg_6-full ];
    text = ''
      ffmpeg \
        -i "$1" \
        -filter:v "crop=1920:1080:(ow-1280)/2:(oh-720)/2" \
        -ss "$2" \
        -t "$3" \
        -c:v h264_nvenc \
        "$4"
    '';
  };
in
{
  home.packages = with pkgs; [
    cut-1080p
    cut-720p
    ffmpeg_6-full
  ];
}
