{
  lib,
  self,
  specialArgs,
  inputs,
  root,
  ...
}:

let
  hostModule =
    { lib, ... }:
    {
      dot.host = {
        user = "haras";
        group = "haras";
        uid = 1000;
        gid = 1000;
        home = "/home/haras";
        pass = lib.mkDefault true;
        version = "24.11";
        hosts = builtins.map (
          x:
          x.config.dot.host
          // {
            system = x.config;
          }
        ) (builtins.attrValues self.nixosConfigurations);
      };
    };
in
{
  flake.nixosModules.host =
    let
      nixosModules = builtins.attrValues (
        lib.filterAttrs (name: _: !(lib.hasPrefix "host" name) && name != "default") self.nixosModules
      );
    in
    { lib, config, ... }:
    {
      imports = [
        inputs.nur.modules.nixos.default
        inputs.nixos-facter-modules.nixosModules.facter
        inputs.sops-nix.nixosModules.default
        inputs.home-manager.nixosModules.default
        inputs.stylix.nixosModules.stylix
        hostModule
      ]
      ++ nixosModules;

      system.stateVersion = config.dot.host.version;

      facter.reportPath = config.dot.host.hardware;

      networking.hostName = config.dot.host.name;

      deploy.node = {
        hostname = config.dot.host.ip;
        sshUser = config.dot.host.user;
      };

      sops.defaultSopsFile = config.dot.host.secrets;
      sops.age.keyFile = "/root/host.scrt.key";
      # FIXME: assumes we're running rumor in some subdir of the repository
      rumor.sops.path = "../${lib.path.removePrefix root config.dot.host.secrets}";
      rumor.specification = {
        imports = [
          {
            importer = "vault";
            arguments = {
              path = "kv/dot/host/${config.dot.host.name}";
              allow_fail = true;
            };
          }
        ];
        exports = [
          {
            exporter = "vault";
            arguments = {
              path = "kv/dot/host/${config.dot.host.name}";
            };
          }
        ];
      };

      users.mutableUsers = false;
      users.groups.${config.dot.host.group} = {
        gid = config.dot.host.gid;
      };
      users.users.${config.dot.host.user} = {
        uid = config.dot.host.uid;
        group = config.dot.host.group;
        isNormalUser = true;
        extraGroups = [
          "wheel"
          "dialout"
        ];
        home = config.dot.host.home;
        initialPassword = lib.mkIf (!config.dot.host.pass) config.dot.host.user;
        createHome = true;
        hashedPasswordFile = lib.mkIf config.dot.host.pass config.sops.secrets."pass-pub".path;
      };
      sops.secrets."pass-pub".neededForUsers = true;
      rumor.sops.keys = [
        "pass-pub"
      ];
      rumor.specification.generations = [
        {
          generator = "mkpasswd";
          arguments = {
            public = "pass-pub";
            private = "pass-priv";
          };
        }
      ];
      home-manager.extraSpecialArgs = specialArgs;
      home-manager.backupFileExtension = "backup";
      home-manager.sharedModules = [
        hostModule
        {
          dot.host.ip = config.dot.host.ip;
          dot.host.interface = config.dot.host.interface;
          dot.host.name = config.dot.host.name;
          dot.host.hardware = config.dot.host.hardware;
          dot.host.secrets = config.dot.host.secrets;
        }
      ];
    };

  flake.homeModules.host =
    let
      homeModules = builtins.attrValues (
        lib.filterAttrs (name: _: !(lib.hasPrefix "host" name) && name != "default") self.homeModules
      );
    in
    { lib, config, ... }:
    {
      imports = [
        inputs.nur.modules.homeManager.default
        inputs.nix-index-database.homeModules.nix-index
        inputs.nixos-facter-modules.hmModules.facter
        inputs.sops-nix.homeManagerModules.sops
      ]
      ++ homeModules;

      home.stateVersion = config.dot.host.version;

      home.username = config.dot.host.user;
      home.homeDirectory = "/home/${config.dot.host.user}";

      facter.reportPath = config.dot.host.hardware;

      sops.defaultSopsFile = config.dot.host.secrets;
      sops.age.keyFile = "/root/host.scrt.key";
    };

  libAttrs.host.mkHost =
    {
      name,
      ip,
      system,
      nixosModule ?
        if self.nixosModules ? "hosts-${name}" then self.nixosModules."hosts-${name}" else { },
      homeModule ? if self.homeModules ? "hosts-${name}" then self.homeModules."hosts-${name}" else { },
      hardware ? lib.path.append root "src/hosts/${name}/hardware.json",
      secrets ? lib.path.append root "src/hosts/${name}/secrets.yaml",
    }:
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        self.nixosModules.host
        nixosModule
        (
          { config, ... }:
          {
            dot.host.name = name;
            dot.host.ip = ip;
            dot.host.interface = "dot";
            dot.host.hardware = hardware;
            dot.host.secrets = secrets;
            home-manager.users.${config.dot.host.user}.imports = [
              self.homeModules.host
              homeModule
            ];
          }
        )
      ];
    };
}
