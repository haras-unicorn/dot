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
  user = "haras";

  version = "24.11";

  hosts =
    builtins.fromTOML
      (builtins.readFile
        (lib.path.append
          root
          "assets/hosts.toml"));
in
{
  seal.rumor.sopsDir = "assets/secrets";
  seal.rumor.specifications =
    builtins.listToAttrs
      (builtins.map
        (host: {
          name = host.name;
          value.imports = [{
            importer = "vault";
            arguments = {
              path = "kv/dot/host/${host.name}";
              allow_fail = true;
            };
          }];
          value.exports = [{
            exporter = "vault";
            arguments = {
              path = "kv/dot/host/${host.name}";
            };
          }];
        })
        hosts.hosts);

  seal.deploy.nodes =
    builtins.listToAttrs
      (builtins.map
        (host: {
          name = host.name;
          value = {
            hostname = host.ip;
            sshUser = user;
          };
        })
        hosts.hosts);

  flake.nixosConfigurations =
    builtins.listToAttrs
      (builtins.map
        (host:
          let
            facterPath =
              lib.path.append
                root
                "assets/hardware/${host.name}.json";

            sopsPath =
              lib.path.append
                root
                "assets/secrets/${host.name}.yaml";

            userHostsModule.options = {
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
              dot.hosts = lib.mkOption {
                type = lib.types.raw;
                default = hosts.hosts;
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
                userHostsModule
                homeManagerModule
                host.home
              ];
              home-manager.users.${user} =
                self.homeManagerModules.default;
            };

            homeManagerModule = { pkgs, ... }: {
              home.stateVersion = version;

              home.username = user;
              home.homeDirectory = "/home/${user}";

              facter.reportPath = facterPath;

              sops.defaultSopsFile = sopsPath;
              sops.age.keyFile = "/root/host.scrt.key";

              # NOTE: https://github.com/nix-community/home-manager/issues/3113
              home.packages = [ pkgs.dconf ];
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
                userHostsModule
                nixosModule
                host.system
              ];
            };
          })
        hosts.hosts);
}
