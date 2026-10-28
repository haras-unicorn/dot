{
  self.homeModules.ffmpeg.value =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.ffmpeg ];
    };
}
