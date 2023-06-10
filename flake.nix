{
  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs;
    home-manager.url = github:nix-community/home-manager; 
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
        ];
      };
    };
}
