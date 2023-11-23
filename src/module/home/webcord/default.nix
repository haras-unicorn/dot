{ pkgs, ... }:

let
  # TODO: like with chromium?
  webcord = pkgs.symlinkJoin {
    name = "webcord";
    paths = [ pkgs.webcord ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/webcord \
        --append-flags --enable-features=WebRTCPipeWireCapturer \
        --append-flags --enable-features=UseOzonePlatform \
        --append-flags --ozone-platform-hint=auto
    '';
  };
in
{
  de.sessionStartup = [
    "${webcord}/bin/webcord"
  ];

  home.packages = [
    webcord
  ];
}
