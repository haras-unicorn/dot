{ self, pkgs, ... }:

let
  run = pkgs.writeShellApplication {
    name = "run";
    text = ''
      "$@" &>/dev/null & disown %-
    '';
  };

  loop = pkgs.writeShellApplication {
    name = "loop";
    text = ''
      while true; do "$@"; done
    '';
  };
in
{
  shell.aliases = {
    pls = "sudo";
    rm = "rm -i";
    mv = "mv -i";
    yas = "yes";
  };

  home.packages = with pkgs; [
    run
    loop
    man-pages
    man-pages-posix
  ];

  imports = [
    "${self}/src/module/home/vivid"
    "${self}/src/module/home/bat"
    "${self}/src/module/home/ripgrep"
    "${self}/src/module/home/sd"
    "${self}/src/module/home/fd"
    "${self}/src/module/home/eza"
  ];
}
