# FIXME: https://github.com/dbeaver/dbeaver/issues/34528#issuecomment-2412519650

{
  machines.homeModules.dbeaver =
    {
      pkgs,
      lib,
      osConfig,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;

      dbeaver = pkgs.symlinkJoin {
        name = "dbeaver";
        paths = [
          pkgs.dbeaver-bin
        ];
        buildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/dbeaver --set GDK_BACKEND x11
        '';
      };
    in
    lib.mkIf hardware.browser {
      home.packages = [
        dbeaver
      ];
    };
}
