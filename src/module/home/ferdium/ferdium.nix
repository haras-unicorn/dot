{ pkgs, ... }:

{
  home.packages = [
    # NOTE: outlook - Self Hosted at https://outlook.office.com/mail/
    (pkgs.symlinkJoin {
      name = "ferdium";
      paths = [ pkgs.ferdium ];
      buildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/ferdium --append-flags --ozone-platform-hint=auto
      '';
    })
  ];
}
