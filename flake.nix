{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";

    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager/release-24.05";
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
  };

  outputs =
    { self
    , flake-utils
    , nixpkgs
    , nix-index-database
    , home-manager
    , nur
    , nixos-facter-modules
    , sops-nix
    , ...
    } @ inputs:
    let
      systemPart = flake-utils.lib.eachDefaultSystem (system:
        {
          devShells.default = self.lib.devShell.mkDevShell system;
        });

      libPart = {
        lib = nixpkgs.lib.mapAttrs'
          (name: value: { inherit name; value = value inputs; })
          (((import "${self}/src/lib/import.nix") inputs).importDir "${self}/src/lib");
      };

      hostPart =
        let
          hosts = (builtins.attrNames (builtins.readDir "${self}/src/host"));
          configs = nixpkgs.lib.cartesianProduct {
            system = flake-utils.lib.defaultSystems;
            host = hosts;
          };
        in
        {
          nixosModules =
            nixpkgs.lib.mergeAttrsList
              (builtins.map self.lib.nixosModule.mkNixosModule configs);

          homeManagerModules =
            nixpkgs.lib.mergeAttrsList
              (builtins.map self.lib.homeManagerModule.mkHomeManagerModule configs);

          nixosConfigurations =
            nixpkgs.lib.mergeAttrsList
              (builtins.map self.lib.nixosConfiguration.mkNixosConfiguration configs);
        };
    in
    systemPart // libPart // hostPart;
}
