{
  self.homeModules.whisper-cpp.value =
    { pkgs, ... }:
    let
      # NOTE: like this because some libs
      # otherwise conflict with other packages
      package = pkgs.buildEnv {
        name = "whisper-cpp";
        paths = [ pkgs.whisper-cpp ];
        pathsToLink = [ "/bin" ];
      };
    in
    {
      home.packages = [
        package
      ];
    };
}
