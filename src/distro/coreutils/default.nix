{ self, pkgs, ... }:

let
  run = pkgs.writeShellApplication {
    name = "run";
    text = ''
      "$@" &>/dev/null & disown %-
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
    "${self}/src/module/home/duf"
  ];
}
