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

  ezdd = pkgs.writeShellApplication {
    name = "ezdd";
    runtimeInputs = [ pkgs.nushell pkgs.gum pkgs.pv ];
    text = ''
      nu ${./ezdd.nu} "$@"
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
      ezdd
      pkgs.htop
      pkgs.man-pages
      pkgs.man-pages-posix
    ];
  };
}
