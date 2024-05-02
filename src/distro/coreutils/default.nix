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
    "${self}/src/module/vivid"
    # "${self}/src/module/bat"
    "${self}/src/module/ripgrep"
    "${self}/src/module/sd"
    "${self}/src/module/fd"
    "${self}/src/module/eza"
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
