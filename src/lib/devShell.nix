{ nixpkgs, ... }:

{
  mkDevShell = system:
    let
      pkgs = import nixpkgs { inherit system; };
    in
    pkgs.mkShell {
      packages = with pkgs; [
        # Nix
        nil
        nixpkgs-fmt

        # Scripts
        yapf
        ruff

        # Misc
        nodePackages.prettier
        nodePackages.yaml-language-server
        nodePackages.vscode-json-languageserver
        marksman
        taplo

        # Tools
        nushell
        just
        openssl
        openvpn
        openssh
        age
        sops
      ];
    };
}
