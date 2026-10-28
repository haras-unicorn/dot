{
  self.homeModules.footage.value =
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
    in
    lib.mkIf hardware.browser {
      home.packages = [
        package
      ];
    };
}
