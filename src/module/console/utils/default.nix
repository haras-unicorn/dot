{ pkgs, ... }:

let
  run = pkgs.writeShellApplication {
    name = "run";
    text = ''
      "$@" &>/dev/null & disown %-
    '';
  };

  repeat = pkgs.writeShellApplication {
    name = "repeat";
    text = ''
      while true; do "$@"; done
    '';
  };
in
{
  shared.dot = {
    shell.aliases = {
      rm = "rm -i";
      mv = "mv -i";
    };
  };

  home = {
    home.packages = [
      run
      repeat
      pkgs.ddrescue
      pkgs.htop
      pkgs.man-pages
      pkgs.man-pages-posix
    ];
  };
}
