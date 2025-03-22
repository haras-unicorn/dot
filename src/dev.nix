{ pkgs, rumor, ... }:

{
  seal.defaults.devShell = "dev";
  integrate.devShell = {
    nixpkgs.config = {
      allowUnfree = true;
    };

    devShell =
      pkgs.mkShell {
        packages = with pkgs; [
          # Nix
          nil
          nixpkgs-fmt

          # Scripts
          just
          nushell
          gum
          fzf

          # Misc
          nodePackages.prettier
          nodePackages.yaml-language-server
          nodePackages.vscode-json-languageserver
          marksman
          taplo

          # Tools
          rumor.packages.${pkgs.system}.default
          nebula
          openssh
          sshpass
          vault
          postgresql
          mysql
          s3cmd
          deploy-rs
          zstd
        ] ++ lib.optionals
          (
            pkgs.stdenv.hostPlatform.isLinux
              && pkgs.stdenv.hostPlatform.isx86_64
          ) [
          libguestfs-with-appliance
        ];
      };
  };
}
