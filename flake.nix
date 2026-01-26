{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-ai.url = "github:nixos/nixpkgs?rev=799ba5bffed04ced7067a91798353d360788b30d";

    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    stylix.url = "github:danth/stylix/release-25.11";

    perch.url = "github:haras-unicorn/perch/refs/tags/1.0.4";
    perch.inputs.nixpkgs.follows = "nixpkgs";

    perch-modules.url = "github:haras-unicorn/perch-modules/refs/tags/1.1.0";
    perch-modules.inputs.nixpkgs.follows = "nixpkgs";
    perch-modules.inputs.perch.follows = "perch";

    rumor.url = "github:haras-unicorn/rumor/refs/tags/1.0.0";
    rumor.inputs.nixpkgs.follows = "nixpkgs";
    rumor.inputs.perch.follows = "perch";

    deploy-rs.url = "github:serokell/deploy-rs";
    deploy-rs.inputs.nixpkgs.follows = "nixpkgs";

    comin.url = "github:nlewo/comin/refs/tags/v0.8.0";
    comin.inputs.nixpkgs.follows = "nixpkgs";

    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    nur.url = "github:nix-community/NUR";
    nur.inputs.nixpkgs.follows = "nixpkgs";

    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";

    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
    nix-vscode-extensions.inputs.nixpkgs.follows = "nixpkgs";

    nixos-facter-modules.url = "github:numtide/nixos-facter-modules";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    nix-comfyui.url = "github:haras-unicorn/nix-comfyui/dev";
    nix-comfyui.inputs.nixpkgs.follows = "nixpkgs-ai";

    musnix.url = "github:musnix/musnix";
    musnix.inputs.nixpkgs.follows = "nixpkgs";

    certilia-overlay.url = "github:marijanp/certilia-overlay";
    certilia-overlay.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    { perch, nixos-facter-modules, ... }@rawInputs:
    let
      inputs = rawInputs // {
        nixos-facter-modules =
          nixos-facter-modules
          // (
            let
              hmModule = (
                { config, lib, ... }:
                {
                  options.facter = {
                    report = lib.mkOption {
                      type = lib.types.raw;
                      default = builtins.fromJSON (builtins.readFile config.facter.reportPath);
                    };

                    reportPath = lib.mkOption {
                      type = lib.types.path;
                    };
                  };
                }
              );
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
