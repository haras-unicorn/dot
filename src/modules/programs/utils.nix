{
  self.homeModules.utils.value =
    {
      pkgs,
      ...
    }:
    let
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
        pkgs.harasPackages.run-disowned
        pkgs.harasPackages.nix-run-nixpkgs
        pkgs.harasPackages.nix-run-unstable
        pkgs.harasPackages.nix-unfree
        pkgs.harasPackages.nix-fast
        pkgs.harasPackages.nix-trace
        pkgs.harasPackages.dd-if-of
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
        pkgs.lsof
        pkgs.usbutils
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
