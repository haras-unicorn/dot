{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nixos-wsl.url = "github:nix-community/NixOS-WSL";
    nixos-wsl.inputs.nixpkgs.follows = "nixpkgs";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    sweet-theme.url = "github:EliverLara/Sweet/nova";
    sweet-theme.flake = false;
  };

  outputs = { self, nixpkgs, home-manager, ... } @ inputs:
    {
      nixosConfigurations.hyperv = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = inputs;
        modules = [
          ./hosts/hyperv/hardware-configuration.nix
          ./hosts/hyperv/configuration.nix
        ];
      };
      nixosConfigurations.virtualbox = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = inputs;
        modules = [
          ./hosts/virtualbox/hardware-configuration.nix
          ./hosts/virtualbox/configuration.nix
        ];
      };
      nixosConfigurations.desktop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = inputs;
        modules = [
          ./hosts/desktop/hardware-configuration.nix
          ./hosts/desktop/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = inputs;
            home-manager.users.virtuoso = import ./hosts/desktop/home.nix;
          }
        ];
      };
      nixosConfigurations.wsl = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = inputs;
        modules = [
          ./hosts/wsl/hardware-configuration.nix
          ./hosts/wsl/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = inputs;
            home-manager.users.nixos = import ./hosts/wsl/home.nix;
          }
        ];
      };
      nixosConfigurations.raspberry-pi = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        specialArgs = inputs;
        modules = [
          ./hosts/raspberry-pi/hardware-configuration.nix
          ./hosts/raspberry-pi/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = inputs;
            home-manager.users.pi = import ./hosts/raspberry-pi/home.nix;
          }
        ];
      };
    };
}
