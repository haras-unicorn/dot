{ pkgs, ... }:

let
  # TODO: like with chromium?
  discord = pkgs.symlinkJoin {
    name = "discord";
    paths = [ pkgs.discord ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/discord \
        --append-flags --enable-features=WebRTCPipeWireCapturer \
        --append-flags --enable-features=UseOzonePlatform \
        --append-flags --ozone-platform-hint=auto
    '';
  };
in
{
  # shared.dot = {
  #   desktopEnvironment.sessionStartup = [
  #     "${discord}/bin/discord"
  #   ];
  # };

  home.shared = {
    home.packages = [
      discord
      pkgs.dorion
      pkgs.webcord
    ];
  };
}
