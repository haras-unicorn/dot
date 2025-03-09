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

            nixosModule = {
              system.stateVersion = version;

              networking.hostName = host.name;

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
                createHome = true;
              };

              home-manager.extraSpecialArgs = specialArgs;
              home-manager.sharedModules = [
                nur.modules.homeManager.default
                nix-index-database.hmModules.nix-index
                nixos-facter-modules.hmModules.facter
                sops-nix.homeManagerModules.sops
                stylix.homeManagerModules.stylix
                homeModule
                host.home
              ];
              home-manager.users.${user} =
                self.homeManagerModules.default;
            };

            homeModule = {
              home.stateVersion = version;

              home.username = user;
              home.homeDirectory = "/home/${user}";

              facter.reportPath = facterPath;

              sops.defaultSopsFile = sopsPath;
              sops.age.keyFile = "/root/host.scrt.key";
            };
          in
          {
            name = "${host.name}-${host.system.system}";
            value = nixpkgs.lib.nixosSystem {
              inherit specialArgs;
              modules = [
                nur.modules.nixos.default
                nixos-facter-modules.nixosModules.facter
                sops-nix.nixosModules.default
                home-manager.nixosModules.default
                self.nixosModules.default
                nixosModule
                host.system
              ];
            };
          })
        hosts.hosts);
}
