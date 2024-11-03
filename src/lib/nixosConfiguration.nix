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

  mkNixosConfiguration = system: host:
    let
      specialArgs = inputs // { inherit version host user; };
    in
    {
      "${host}-${system}" = nixpkgs.lib.nixosSystem {
        inherit system specialArgs;
        modules = [
          nur.nixosModules.nur
          nixos-facter-modules.nixosModules.facter
          sops-nix.nixosModules.sops
          home-manager.nixosModules.home-manager
          self.nixosModules."${host}-${system}"
        ];
      };
    };
}
