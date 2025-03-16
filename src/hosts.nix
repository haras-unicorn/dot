{ self
, root
, lib
, nixpkgs
, specialArgs
, nur
, nixos-facter-modules
, sops-nix
, home-manager
, nix-index-database
, stylix
, ...
}:

let
  hosts =
    builtins.fromTOML
      (builtins.readFile
        (lib.path.append
          root
          "assets/hosts.toml"));
in
{
  seal.rumor =
    builtins.listToAttrs
      (builtins.map
        (host: {
          name = host.name;
          value.importers = [{
            importer = "vault";
            path = "kv/dot/host/${host.name}";
          }];
          value.exporters = [{
            exporter = "vault";
            path = "kv/dot/host/${host.name}";
          }];
        })
        hosts.hosts);

  flake.nixosConfigurations =
    builtins.listToAttrs
      (builtins.map
        (host:
          let
            user = "haras";

            version = "24.11";

            facterPath =
              lib.path.append
                root
                "assets/hardware/${host.name}.json";

            sopsPath =
              lib.path.append
                root
                "assets/secrets/${host.name}.yaml";

            userHostModule.options = {
              dot.user = lib.mkOption {
                type = lib.types.str;
                default = user;
              };
              dot.host.name = lib.mkOption {
                type = lib.types.str;
                default = host.name;
              };
              dot.host.ip = lib.mkOption {
                type = lib.types.str;
                default = host.ip;
              };
            };

            nixosModule = {
              system.stateVersion = version;

              facter.reportPath = facterPath;

              sops.defaultSopsFile = sopsPath;
              sops.age.keyFile = "/root/host.scrt.key";

              users.mutableUsers = false;
              users.groups.${user} = { };
              users.users.${user} = {
                group = user;
                isNormalUser = true;
                extraGroups = [ "wheel" "dialout" ];
                home = "/home/${user}";
                initialPassword = user;
                createHome = true;
              };

              home-manager.extraSpecialArgs = specialArgs;
              home-manager.sharedModules = [
                nur.modules.homeManager.default
                nix-index-database.hmModules.nix-index
                nixos-facter-modules.hmModules.facter
                sops-nix.homeManagerModules.sops
                stylix.homeManagerModules.stylix
                userHostModule
                homeManagerModule
                host.home
              ];
              home-manager.users.${user} =
                self.homeManagerModules.default;
            };

            homeManagerModule = {
              home.stateVersion = version;

              home.username = user;
              home.homeDirectory = "/home/${user}";

              facter.reportPath = facterPath;

              sops.defaultSopsFile = sopsPath;
              sops.age.keyFile = "/root/host.scrt.key";
            };
          in
          {
            name = "${host.name}-${host.system.nixpkgs.system}";
            value = nixpkgs.lib.nixosSystem {
              inherit specialArgs;
              modules = [
                nur.modules.nixos.default
                nixos-facter-modules.nixosModules.facter
                sops-nix.nixosModules.default
                home-manager.nixosModules.default
                self.nixosModules.default
                userHostModule
                nixosModule
                host.system
              ];
            };
          })
        hosts.hosts);
}
