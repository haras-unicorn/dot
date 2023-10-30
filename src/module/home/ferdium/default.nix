{ pkgs, ... }:

# NOTE: outlook - Self Hosted at https://outlook.office.com/mail/

let
  # TODO: like with chromium?
  ferdium = pkgs.symlinkJoin {
    name = "ferdium";
    paths = [ pkgs.ferdium ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/ferdium \
        --append-flags --ozone-platform-hint=auto
    '';
  };
in
{
  # TODO: systemd
  wayland.windowManager.hyprland.extraConfig = ''
    exec-once = ${ferdium}/bin/ferdium
  '';

  home.packages = [
    ferdium
  ];
}
