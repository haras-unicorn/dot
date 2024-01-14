{ pkgs, ... }:

let
  # TODO: like with chromium?
  teams = pkgs.symlinkJoin {
    name = "teams";
    paths = [ pkgs.teams-for-linux ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/teams \
        --append-flags --enable-features=WebRTCPipeWireCapturer \
        --append-flags --enable-features=UseOzonePlatform \
        --append-flags --ozone-platform-hint=auto
    '';
  };
in
{
  de.sessionStartup = [
    "${teams}/bin/teams"
  ];

  home.packages = [
    teams
  ];
}
