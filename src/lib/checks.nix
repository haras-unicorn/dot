{ self, nixpkgs, deploy-rs, ... }:

{
  mkChecks = system:
    let
      pkgs = import nixpkgs { inherit system; };

      deployChecks = deploy-rs.lib.${system}.deployChecks self.deploy;

      selfChecks = {
        just = pkgs.writeShellApplication {
          name = "just";
          runtimeInputs = [ pkgs.just ];
          text = ''
            cd "$(git rev-parse --show-toplevel)"
            just --unstable --fmt --check
          '';
        };
        prettier = pkgs.writeShellApplication {
          name = "prettier";
          runtimeInputs = [ pkgs.nodePackages.prettier ];
          text = ''
            prettier --check "$(git rev-parse --show-toplevel)"
          '';
        };
        nixpkgs-fmt = pkgs.writeShellApplication {
          name = "nixpkgs-fmt";
          runtimeInputs = [ pkgs.nixpkgs-fmt ];
          text = ''
            nixpkgs-fmt "$(git rev-parse --show-toplevel)"
          '';
        };
      };
    in
    selfChecks // deployChecks;
}
