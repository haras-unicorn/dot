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
    let toml = builtins.fromTOML (builtins.readFile ./hosts.toml);
    in toml.hosts;
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
        hosts);

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
        hosts);

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
              dot.pass = lib.mkOption {
                type = lib.types.bool;
                default = true;
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
                default = hosts;
              };
            };

            nixosModule = { config, ... }: {
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
                initialPassword = lib.mkIf
                  (!config.dot.pass)
                  user;
                createHome = true;
                hashedPasswordFile = lib.mkIf
                  config.dot.pass
                  config.sops.secrets."pass-pub".path;
              };
              sops.secrets."pass-pub".neededForUsers = true;

              home-manager.extraSpecialArgs = specialArgs;
              home-manager.backupFileExtension = "backup";
              home-manager.sharedModules = [
                nur.modules.homeManager.default
                nix-index-database.hmModules.nix-index
                nixos-facter-modules.hmModules.facter
                sops-nix.homeManagerModules.sops
                stylix.homeModules.stylix
                userHostsModule
                homeManagerModule
                host.home
              ];
              home-manager.users.${user} =
                self.homeManagerModules.default;

              rumor.sops = [
                "pass-pub"
              ];
              rumor.specification.generations = [{
                generator = "mkpasswd";
                arguments = {
                  public = "pass-pub";
                  private = "pass-priv";
                };
              }];
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
        hosts);
}
