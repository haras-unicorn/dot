{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    perch.url = "github:altibiz/perch/refs/tags/2.1.1";
    perch.inputs.nixpkgs.follows = "nixpkgs";

    rumor.url = "github:altibiz/rumor/refs/tags/1.1.3";
    rumor.inputs.nixpkgs.follows = "nixpkgs";
    rumor.inputs.perch.follows = "perch";

    deploy-rs.url = "github:serokell/deploy-rs";
    deploy-rs.inputs.nixpkgs.follows = "nixpkgs";

    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nur.url = "github:nix-community/NUR";
    nur.inputs.nixpkgs.follows = "nixpkgs";

    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
    nix-vscode-extensions.inputs.nixpkgs.follows = "nixpkgs";

    nixos-facter-modules.url = "github:numtide/nixos-facter-modules";

    lanzaboote.url = "github:nix-community/lanzaboote/v0.4.1";
    lanzaboote.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    nix-colors.url = "github:Misterio77/nix-colors";

    nix-comfyui.url = "github:haras-unicorn/nix-comfyui/dev";
    nix-comfyui.inputs.nixpkgs.follows = "nixpkgs";

    musnix.url = "github:musnix/musnix";
    musnix.inputs.nixpkgs.follows = "nixpkgs";

    stylix.url = "github:danth/stylix/release-24.11";
    stylix.inputs.home-manager.follows = "home-manager";
  };

  outputs =
    { perch, nixos-facter-modules, ... } @ rawInputs:
    let
      inputs = rawInputs // {
        nixos-facter-modules = nixos-facter-modules // (
          let
            hmModule = ({ config, lib, ... }: {
              options.facter = {
                report = lib.mkOption {
                  type = lib.types.raw;
                  default = builtins.fromJSON
                    (builtins.readFile config.facter.reportPath);
                };

                reportPath = lib.mkOption {
                  type = lib.types.path;
                };
              };
            });
          in
          {
            hmModules.facter = hmModule;
          }
        );
      };
    in
    perch.lib.flake.make {
      inherit inputs;
      root = ./.;
      prefix = "src";
    };
}
