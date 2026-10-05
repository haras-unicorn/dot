{
  machines.homeModules.utils =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      run-disowned = pkgs.writeShellApplication {
        name = "run-disowned";
        text = ''
          "$@" &>/dev/null & disown %-
        '';
      };

      nix-run-nixpkgs = pkgs.writeShellApplication {
        name = "nix-run-nixpkgs";
        text = ''
          name="$1"
          shift
          exec nix run "nixpkgs#$name" -- "$@"
        '';
      };

      nix-run-unstable = pkgs.writeShellApplication {
        name = "nruu";
        text = ''
          name="$1"
          shift
          exec nix run --impure "github:nixos/nixpkgs/nixos-unstable#$name" -- "$@"
        '';
      };

      nix-unfree = pkgs.writeShellApplication {
        name = "nix-unfree";
        text = ''
          export NIXPKGS_ALLOW_UNFREE=1
          exec "$@"
        '';
      };

      nix-fast = pkgs.writeShellApplication {
        name = "nix-fast";
        text = ''
          export NIX_CONFIG="''${NIX_CONFIG:-}
          max-jobs = auto
          cores = 0"
          exec "$@"
        '';
      };

      nix-trace = pkgs.writeShellApplication {
        name = "nix-trace";
        text = ''
          export NIX_CONFIG="''${NIX_CONFIG:-}
          show-trace = true"
          exec "$@"
        '';
      };

      dd-if-of = pkgs.writeShellApplication {
        name = "dd-if-of";
        text = ''
          if="$1"
          of="$2"
          shift
          shift
          exec dd "if=$if" "of=$of" bs=4M conv=sync,noerror oflag=direct status=progress "$@"
        '';
      };

      ssh-test-container = pkgs.writeShellApplication {
        name = "ssh-test-container";
        runtimeInputs = [
          pkgs.openssh
          pkgs.socat
        ];
        text = ''
          name="$1"
          shift
          ssh \
            -o User=root \
            -o ProxyCommand="socat - UNIX-CLIENT:/run/systemd/nspawn/unix-export/$name/ssh" \
            -o "UserKnownHostsFile=/dev/null" \
            -o "StrictHostKeyChecking=accept-new" \
            bash "$@"
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
        run-disowned
        nix-run-nixpkgs
        nix-run-unstable
        nix-unfree
        nix-fast
        nix-trace
        dd-if-of
        ssh-test-container
        pkgs.htop
        pkgs.duf
        pkgs.dua
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
        pkgs.lnav
        pkgs.jq
        pkgs.tokei
        pkgs.openssh
        pkgs.openssl
        pkgs.iw
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
