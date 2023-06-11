{
  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs;
    home-manager.url = github:nix-community/home-manager; 
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, ... } @ inputs: 
    let 
      system = "x86_64-linux";
    in {
      nixosConfigurations.hyperv = nixpkgs.lib.nixosSystem {
        system = "${system}";
        specialArgs = inputs;
        modules = [
          ./hosts/hyperv/configuration.nix
        ];
      };
      nixosConfigurations.virtualbox = nixpkgs.lib.nixosSystem {
        system = "${system}";
        specialArgs = inputs;
        modules = [
          ./hosts/virtualbox/configuration.nix
        ];
      };
      nixosConfigurations.desktop = nixpkgs.lib.nixosSystem {
        system = "${system}";
        specialArgs = inputs;
        modules = [
          ./hosts/desktop/configuration.nix
          home-manager.nixosModules.home-manager {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.virtuoso = {
              imports = [ ./hosts/desktop/home.nix ]; 
            };
          }
        ];
      };
    };
}
