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

  nr = pkgs.writeShellApplication {
    name = "nr";
    text = ''
      name="$1"
      shift
      exec nix run "nixpkgs#$name" -- "$@"
    '';
  };

  nru = pkgs.writeShellApplication {
    name = "nru";
    text = ''
      export NIXPKGS_ALLOW_UNFREE=1
      name="$1"
      shift
      exec nix run --impure "nixpkgs#$name" -- "$@"
    '';
  };

  nruu = pkgs.writeShellApplication {
    name = "nruu";
    text = ''
      export NIXPKGS_ALLOW_UNFREE=1
      name="$1"
      shift
      exec nix run --impure "github:nixos/nixpkgs/nixos-unstable#$name" -- "$@"
    '';
  };

  ezdd = pkgs.writeShellApplication {
    name = "ezdd";
    text = ''
      if="$1"
      of="$2"
      shift
      shift
      exec dd "if=$if" "of=$of" bs=4M conv=sync,noerror oflag=direct status=progress "$@"
    '';
  };
in
{
  home = {
    home.packages = [
      run
      repeat
      nr
      nru
      nruu
      ezdd
      pkgs.htop
      pkgs.duf
      pkgs.nvtopPackages.full
      pkgs.man-pages
      pkgs.man-pages-posix
      pkgs.rustscan
    ];
  };
}
