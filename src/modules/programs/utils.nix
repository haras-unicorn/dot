{ ... }:

{
  machines.homeModules.utils =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      run = pkgs.writeShellApplication {
        name = "run";
        runtimeInputs = [
          pkgs.coreutils
        ];
        text = ''
          "$@" &>/dev/null & disown %-
        '';
      };

      repeat = pkgs.writeShellApplication {
        name = "repeat";
        runtimeInputs = [
          pkgs.coreutils
        ];
        text = ''
          while true; do "$@"; done
        '';
      };

      nr = pkgs.writeShellApplication {
        name = "nr";
        runtimeInputs = [
          pkgs.coreutils
        ];
        text = ''
          name="$1"
          shift
          exec nix run "nixpkgs#$name" -- "$@"
        '';
      };

      nru = pkgs.writeShellApplication {
        name = "nru";
        runtimeInputs = [
          pkgs.coreutils
        ];
        text = ''
          export NIXPKGS_ALLOW_UNFREE=1
          name="$1"
          shift
          exec nix run --impure "nixpkgs#$name" -- "$@"
        '';
      };

      nruu = pkgs.writeShellApplication {
        name = "nruu";
        runtimeInputs = [
          pkgs.coreutils
        ];
        text = ''
          export NIXPKGS_ALLOW_UNFREE=1
          name="$1"
          shift
          exec nix run --impure "github:nixos/nixpkgs/nixos-unstable#$name" -- "$@"
        '';
      };

      ezdd = pkgs.writeShellApplication {
        name = "ezdd";
        runtimeInputs = [
          pkgs.coreutils
        ];
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
      # FIXME: its not finding the grammars?
      xdg.configFile."tree-sitter/config.json".text = builtins.toJSON {
        "parser-directories" = [
          (pkgs.tree-sitter.withPlugins (p: builtins.attrValues p))
        ];
      };

      home.packages = [
        run
        repeat
        nr
        nru
        nruu
        ezdd
        pkgs.htop
        pkgs.duf
        pkgs.man-pages
        pkgs.man-pages-posix
        pkgs.rustscan
        pkgs.fd
        pkgs.vim
        pkgs.usql
        pkgs.fastmod
        pkgs.rnr
        pkgs.ast-grep
        pkgs.tree-sitter
        (pkgs.rustPlatform.buildRustPackage (
          let
            version = "1.3.0";
          in
          {
            inherit version;
            pname = "stdrename";
            src = pkgs.fetchFromGitHub {
              owner = "Gadiguibou";
              repo = "stdrename";
              rev = "v${version}";
              sha256 = "sha256-DdxHNwL108t2C5LN/sMxq5VqyYtDrKXgJeO45ZJvHdA=";
            };
            cargoHash = "sha256-A/lrfI4SUPoVrCnSFew76vHK6B0IDjJsgJsGamMbZnQ=";
            meta = {
              description = "Small command line utility to rename all files in a folder according to a specified naming convention (camelCase, snake_case, kebab-case, etc.).";
              homepage = "https://github.com/Gadiguibou/stdrename";
              license = pkgs.lib.licenses.gpl3;
            };
          }
        ))
      ];
    };
}
