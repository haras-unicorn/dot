{
  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs;
  };

  outputs = { self, nixpkgs, ... } @ inputs: 
    let 
      system = "x86_64-linux";
    in {
      nixosConfigurations.hyperv = nixpkgs.lib.nixosSystem {
        system = "${system}";
        modules = [
          ./hosts/hyperv/configuration.nix
        ]
      };
      nixosConfigurations.virtualbox = nixpkgs.lib.nixosSystem {
        system = "${system}";
        modules = [
          ./hosts/virtualbox/configuration.nix
        ]
      };
    };
}