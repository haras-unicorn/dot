{ nixpkgs, ... }:

# TODO: uncomment nufmt once it gets better

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
      ];
    };
}
