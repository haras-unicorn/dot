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
  group = "users";
  uid = 1000;
  gid = 100;

  mkModules = mkModule: builtins.map
    (x: mkModule x.__import.value x.__import.path)
    (builtins.filter
      (x: x.__import.type == "default")
      (nixpkgs.lib.collect
        (builtins.hasAttr "__import")
        (self.lib.import.importDirMeta "${self}/src/module")));
in
{
  inherit user group uid gid version mkModules;

  mkNixosConfiguration = host: system:
    let
      specialArgs = inputs // { inherit version host system user group uid gid; };
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
