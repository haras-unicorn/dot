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
in
{
  inherit user group uid gid version;

  mkNixosConfiguration = host: system:
    let
      specialArgs = inputs // { inherit version host system user group uid gid; };
    in
    nixpkgs.lib.nixosSystem {
      inherit system specialArgs;
      modules = [
        nur.modules.nixos.nur
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
