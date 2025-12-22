{ pkgs, rumor, ... }:

{
  defaultDevShell = true;
  devShellNixpkgs.config.allowUnfree = true;
  devShell = pkgs.mkShell {
    packages =
      with pkgs;
      [
        # Nix
        nil
        nixfmt-rfc-style

        # Scripts
        just
        nushell
        gum
        fzf
        fd

        # Misc
        nodePackages.prettier
        nodePackages.yaml-language-server
        nodePackages.vscode-langservers-extracted
        markdownlint-cli
        nodePackages.markdown-link-check
        marksman
        taplo

        # Tools
        nodePackages.cspell
        nixos-generators
        rumor.packages.${pkgs.system}.default
        nebula
        openssh
        sshpass
        vault
        vault-medusa
        postgresql
        mariadb
        s3cmd
        deploy-rs
        zstd
      ]
      ++ lib.optionals (pkgs.stdenv.hostPlatform.isLinux && pkgs.stdenv.hostPlatform.isx86_64) [
        libguestfs-with-appliance
      ];
  };
}
