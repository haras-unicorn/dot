{ pkgs, lib, config, ... }:

# FIXME: https://github.com/dbeaver/dbeaver/issues/34528#issuecomment-2412519650
# TODO: customize custom dbeaver colors

let
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

  hasMonitor = config.dot.hardware.monitor.enable;
in
{
  branch.homeManagerModule.homeManagerModule = lib.mkIf hasMonitor {
    home.packages = [
      dbeaver
    ];
  };
}
