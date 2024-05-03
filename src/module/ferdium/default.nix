{ pkgs, ... }:

# FIXME: screen sharing

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
        --append-flags --enable-features=WebRTCPipeWireCapturer \
        --append-flags --enable-features=UseOzonePlatform \
        --append-flags --ozone-platform-hint=auto
    '';
  };
in
{
  shared = {
    dot = {
      desktopEnvironment.sessionStartup = [
        "${ferdium}/bin/ferdium"
      ];
    };
  };

  home.shared = {
    home.packages = [
      ferdium
    ];
  };
}
