{ self
, nixpkgs
, nur
, nixos-facter-modules
, sops-nix
, home-manager
, ...
} @inputs:

let
  user = "haras";
  version = "24.11";
  modules = builtins.attrValues (self.lib.import.importDir "${self}/src/module");
in
{
  inherit user version modules;

  mkNixosConfiguration = host: system:
    let
      specialArgs = inputs // { inherit version host user; };
    in
    nixpkgs.lib.nixosSystem {
      inherit system specialArgs;
      modules = [
        nur.nixosModules.default
        nixos-facter-modules.nixosModules.default
        sops-nix.nixosModules.default
        home-manager.nixosModules.default
        self.nixosModules."${host}-${system}"
      ];
    };
}
