{
  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs;
    nixpkgs-unstable.url = "nixpkgs/nixpkgs-unstable";
    home-manager.url = github:nix-community/home-manager;
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, ... } @ inputs: 
    let 
      system = "x86_64-linux";
    in {
      nixosConfigurations.desktop = nixpkgs.lib.nixosSystem {
        system = "${system}";
      };
    };
}