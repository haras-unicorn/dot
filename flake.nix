{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";

    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    nixpkgs-unstable = "github:nixos/nixpkgs/nixos-unstable";

    deploy-rs.url = "github:serokell/deploy-rs";
    deploy-rs.inputs.nixpkgs.follows = "nixpkgs";
    deploy-rs.inputs.utils.follows = "flake-utils";

    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nur.url = "github:nix-community/NUR";

    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
    nix-vscode-extensions.inputs.nixpkgs.follows = "nixpkgs";

    nixos-facter-modules.url = "github:numtide/nixos-facter-modules";

    lanzaboote.url = "github:nix-community/lanzaboote/v0.4.1";
    lanzaboote.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    arkenfox-userjs.url = "github:arkenfox/user.js/refs/tags/v110.0";
    arkenfox-userjs.flake = false;

    firefox-gx.url = "github:Godiesc/firefox-gx/refs/tags/v.9.0";
    firefox-gx.flake = false;

    tint-gear.url = "github:haras-unicorn/tint-gear";
    tint-gear.inputs.nixpkgs.follows = "nixpkgs";

    nix-colors.url = "github:Misterio77/nix-colors";

    nix-comfyui.url = "github:haras-unicorn/nix-comfyui/dev";
    nix-comfyui.inputs.nixpkgs.follows = "nixpkgs";
    nix-comfyui.inputs.flake-utils.follows = "flake-utils";

    musnix.url = "github:musnix/musnix";
    musnix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    { self
    , flake-utils
    , nixpkgs
    , deploy-rs
    , nixos-facter-modules
    , ...
    } @ rawInputs:
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

      libPart = {
        lib = nixpkgs.lib.mapAttrs'
          (name: value: { inherit name; value = value inputs; })
          (((import "${self}/src/lib/import.nix") inputs).importDir "${self}/src/lib");
      };

      systemPart = flake-utils.lib.eachDefaultSystem (system: {
        devShells.default = self.lib.devShell.mkDevShell system;
        formatter = self.lib.formatter.mkFormatter system;
        checks = self.lib.checks.mkChecks system;
      });

      hostPart =
        let
          invokeForHostSystemMatrix = mk: nixpkgs.lib.mergeAttrsList
            (builtins.map
              ({ host, system }: {
                "${host}-${system}" = mk host system;
              })
              (nixpkgs.lib.cartesianProduct {
                host = (builtins.attrNames (builtins.readDir "${self}/src/host"));
                system = flake-utils.lib.defaultSystems;
              }));
        in
        {
          nixosModules = invokeForHostSystemMatrix self.lib.nixosModule.mkNixosModule;
          hmModules = invokeForHostSystemMatrix self.lib.hmModule.mkHmModule;
          nixosConfigurations = invokeForHostSystemMatrix self.lib.nixosConfiguration.mkNixosConfiguration;
          deploy.nodes = invokeForHostSystemMatrix self.lib.deploy.mkDeploy;
        };
    in
    libPart // systemPart // hostPart;
}
