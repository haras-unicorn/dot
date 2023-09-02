{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    nixpkgs-stable.url = "github:NixOS/nixpkgs/release-23.05";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nixos-wsl.url = "github:nix-community/NixOS-WSL";
    nixos-wsl.inputs.nixpkgs.follows = "nixpkgs";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.inputs.nixpkgs-stable.follows = "nixpkgs-stable";

    sweet-theme.url = "github:EliverLara/Sweet/nova";
    sweet-theme.flake = false;
  };

  outputs = { self, nixpkgs, home-manager, sops-nix, ... } @ inputs:
    {
      nixosConfigurations =
        builtins.foldl'
          (nixosConfigurations: host:
            nixpkgs.lib.nixosSystem
              (
                let
                  meta = builtins.import "./hosts/${host}/meta.nix";
                in
                nixosConfigurations // {
                  "${host}" = {
                    system = meta.system;
                    specialArgs = inputs // {
                      username = "haras";
                      hostname = "haras-${host}";
                    };
                    modules = [
                      ./host/${host}/hardware-configuration.nix
                      ./host/${host}/configuration.nix
                    ]
                    ++ (if (builtins.pathExists "./hosts/${host}/home.nix") then [
                      home-manager.nixosModules.home-manager
                      {
                        home-manager.useGlobalPkgs = true;
                        home-manager.useUserPackages = true;
                        home-manager.extraSpecialArgs = inputs;
                        home-manager.users.haras = import ./hosts/${host}/home.nix;
                      }
                    ] else [ ])
                    ++ (if (builtins.pathExists "./hosts/${host}/secrets.nix") then [
                      sops-nix.nixosModules.sops
                      ./host/${host}/secrets.nix
                    ] else [ ]);
                  };
                }
              ))
          { }
          (builtins.attrNames
            (builtins.readDir "./hosts"));
    };
}
