{
  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-channels";
    nixpkgs-unstable.url = "nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, ... } @ inputs: 
    let 
      system = "x86_64-linux";
    in {
      nixosConfigurations.desktop = {
        system = "${system}";
      };
    };
}