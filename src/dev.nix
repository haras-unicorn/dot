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
        fzf
        # nufmt

        # Misc
        nodePackages.prettier
        nodePackages.yaml-language-server
        nodePackages.vscode-json-languageserver
        marksman
        taplo

        # Tools
        openssl
        openvpn
        openssh
        age
        sops
        nebula
        deploy-rs
        vaultwarden
      ];
    };
}
