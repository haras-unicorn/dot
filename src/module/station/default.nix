{ pkgs, ... }:

# FIXME: webrtc so i dont need desktop apps

# TODO: like with chromium?
# TODO: hardware related stuff elsewhere

let
  station = pkgs.symlinkJoin {
    name = "station";
    paths = [ pkgs.station ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/station \
        --append-flags --enable-features=UseOzonePlatform \
        --append-flags --enable-features=WebRTCPipeWireCapturer \
        --append-flags --ozone-platform-hint=auto \
        --append-flags --no-sandbox
    '';
  };
in
{
  home.shared = {
    de.sessionStartup = [
      "${station}/bin/station"
    ];

    home.packages = [
      station
    ];
  };
}
