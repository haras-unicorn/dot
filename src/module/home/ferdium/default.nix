{ pkgs, ... }:

# FIXME: webrtc so i dont need desktop apps

# NOTE: outlook - Self Hosted at https://outlook.office.com/mail/
# NOTE: WebRTC handling - set share all IPs so discord WebRTC works
# TODO: like with chromium?
# TODO: hardware related stuff elsewhere

let
  ferdium = pkgs.symlinkJoin {
    name = "ferdium";
    paths = [ pkgs.ferdium ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/ferdium \
        --append-flags --enable-features=UseOzonePlatform,WebRTCPipeWireCapturer,WaylandWindowDecorations \
        --append-flags --ozone-platform=wayland \
        --append-flags --ozone-platform-hint=auto
    '';
  };
in
{
  de.sessionStartup = [
    "${ferdium}/bin/ferdium"
  ];

  home.packages = [
    ferdium
  ];
}
