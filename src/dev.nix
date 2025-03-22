{ pkgs, ... }:

{
  seal.defaults.devShell = "dev";
  integrate.devShell.devShell =
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
        nebula
        deploy-rs
        vaultwarden
        vault
        cockroachdb
      ];
    };
}
