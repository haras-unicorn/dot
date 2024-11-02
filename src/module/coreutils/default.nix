{ pkgs, ... }:

# FIXME: bat cache
# TODO: proper repeat

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
  shared = {
    dot = {
      shell.aliases = {
        pls = "sudo";
        rm = "rm -i";
        mv = "mv -i";
        yas = "yes";
      };
    };
  };

  home = {
    home.packages = with pkgs; [
      run
      repeat
      htop
      man-pages
      man-pages-posix
    ];
  };
}
