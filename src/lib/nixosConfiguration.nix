{ self
, nixpkgs
, nur
, nixos-facter-modules
, sops-nix
, home-manager
, nix-index-database
, ...
} @inputs:

let
  version = "24.05";
  user = "haras";

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
      specialArgs = inputs // { inherit version host system user; };
    in
    nixpkgs.lib.nixosSystem {
      inherit system specialArgs;
      modules = [
        nur.nixosModules.nur
        nixos-facter-modules.nixosModules.facter
        sops-nix.nixosModules.default
        home-manager.nixosModules.default
        self.nixosModules."${host}-${system}"
        {
          home-manager.backupFileExtension = "backup";
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = specialArgs;
          home-manager.sharedModules = [
            nur.hmModules.nur
            nix-index-database.hmModules.nix-index
            nixos-facter-modules.hmModules.facter
            sops-nix.homeManagerModules.sops
          ];
          home-manager.users."${user}" = self.hmModules."${host}-${system}";
        }
      ];
    };
}
