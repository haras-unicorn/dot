{ pkgs, ... }:

# FIXME: screen sharing

let
  station = pkgs.symlinkJoin {
    name = "station";
    paths = [ pkgs.station ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/station \
        --append-flags --enable-features=UseOzonePlatform \
        --append-flags --enable-features=WebRTCPipeWireCapturer \
        --append-flags --ozone-platform-hint=auto
    '';
  };
in
{
  home = {
    de.sessionStartup = [
      "${station}/bin/station"
    ];

    home.packages = [
      station
    ];
  };
}
