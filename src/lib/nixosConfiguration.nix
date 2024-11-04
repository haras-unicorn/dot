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
  modules = builtins.map
    (x: x.__import.value)
    (builtins.filter
      (x: x.__import.type == "default")
      (nixpkgs.lib.collect
        (builtins.hasAttr "__import")
        (self.lib.import.importDirMeta "${self}/src/module")));
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
        nur.nixosModules.nur
        nixos-facter-modules.nixosModules.facter
        sops-nix.nixosModules.default
        home-manager.nixosModules.default
        self.nixosModules."${host}-${system}"
      ];
    };
}
