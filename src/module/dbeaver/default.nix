{ pkgs, ... }:

# FIXME: https://github.com/dbeaver/dbeaver/issues/34528#issuecomment-2412519650

let
  dbeaver = pkgs.symlinkJoin {
    name = "dbeaver";
    paths = [
      pkgs.dbeaver
    ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/dbeaver --set GDK_BACKEND x11
    '';
  };
in
{
  home.shared = {
    home.packages = [
      dbeaver
    ];
  };
}
