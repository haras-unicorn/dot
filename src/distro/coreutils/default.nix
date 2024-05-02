{ self, pkgs, ... }:

# FIXME: bat cache

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
  imports = [
    "${self}/src/module/home/vivid"
    # "${self}/src/module/home/bat"
    "${self}/src/module/home/ripgrep"
    "${self}/src/module/home/sd"
    "${self}/src/module/home/fd"
    "${self}/src/module/home/eza"
  ];

  home.shared = {
    shell.aliases = {
      pls = "sudo";
      rm = "rm -i";
      mv = "mv -i";
      yas = "yes";
    };

    home.packages = with pkgs; [
      run
      repeat
      man-pages
      man-pages-posix
    ];
  };
}
