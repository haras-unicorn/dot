{
  lib,
  config,
  specialArgs,
  inputs,
  root,
  ...
}:

let
  nixosConfigurations = config.flake.nixosConfigurations;

  nixosModules = config.flake.nixosModules;

  homeModules = config.flake.homeModules;

  hostModule =
    { lib, config, ... }:
    {
      options.dot.host = {
        name = lib.mkOption {
          type = lib.types.str;
        };
        ip = lib.mkOption {
          type = lib.types.str;
        };
        facterPath = lib.mkOption {
          type = lib.types.path;
        };
        sopsPath = lib.mkOption {
          type = lib.types.path;
        };
        user = lib.mkOption {
          type = lib.types.str;
          default = "haras";
        };
        pass = lib.mkOption {
          type = lib.types.bool;
          default = true;
        };
        version = lib.mkOption {
          type = lib.types.str;
          default = "24.11";
        };
        hosts = lib.mkOption {
          type = lib.types.listOf lib.types.raw;
          default = builtins.map (
            x:
            x.config.dot.host
            // {
              system = x.config;
            }
          ) (builtins.attrValues nixosConfigurations);
        };
      };
    };
in
{
  flake.nixosModules.host =
    let
      nixosModules = builtins.attrValues (
        lib.filterAttrs (
          name: _: !(lib.hasPrefix "host" name) && name != "default"
        ) config.flake.nixosModules
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

      facter.reportPath = config.dot.host.facterPath;

      networking.hostName = config.dot.host.name;
      dot.nebula.ip = config.dot.host.ip;
      dot.nebula.subnet.ip = "10.69.42.0";
      dot.nebula.subnet.bits = 24;
      dot.nebula.subnet.mask = "255.255.255.0";

      deploy.node = {
        hostname = config.dot.host.ip;
        sshUser = config.dot.host.user;
      };

      sops.defaultSopsFile = config.dot.host.sopsPath;
      sops.age.keyFile = "/root/host.scrt.key";
      # NOTE: assumes we're running rumor in some subdir of the repository
      rumor.sops.path = "../${lib.path.removePrefix root config.dot.host.sopsPath}";
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
      users.groups.${config.dot.host.user} = {
        gid = 1000;
      };
      users.users.${config.dot.host.user} = {
        uid = 1000;
        group = config.dot.host.user;
        isNormalUser = true;
        extraGroups = [
          "wheel"
          "dialout"
        ];
        home = "/home/${config.dot.host.user}";
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
          dot.host.name = config.dot.host.name;
          dot.host.facterPath = config.dot.host.facterPath;
          dot.host.sopsPath = config.dot.host.sopsPath;
        }
      ];
    };

  flake.homeModules.host =
    let
      homeModules = builtins.attrValues (
        lib.filterAttrs (
          name: _: !(lib.hasPrefix "host" name) && name != "default"
        ) config.flake.homeModules
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

      facter.reportPath = config.dot.host.facterPath;

      sops.defaultSopsFile = config.dot.host.sopsPath;
      sops.age.keyFile = "/root/host.scrt.key";
    };

  libAttrs.host.mkHost =
    {
      name,
      ip,
      system,
      nixosModule ? if nixosModules ? "hosts-${name}" then nixosModules."hosts-${name}" else { },
      homeModule ? if homeModules ? "hosts-${name}" then homeModules."hosts-${name}" else { },
      facterPath ? lib.path.append root "src/hosts/${name}/hardware.json",
      sopsPath ? lib.path.append root "src/hosts/${name}/secrets.yaml",
    }:
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        nixosModules.host
        nixosModule
        (
          { config, ... }:
          {
            dot.host.name = name;
            dot.host.ip = ip;
            dot.host.facterPath = facterPath;
            dot.host.sopsPath = sopsPath;
            home-manager.users.${config.dot.host.user}.imports = [
              homeModules.host
              homeModule
            ];
          }
        )
      ];
    };
}
