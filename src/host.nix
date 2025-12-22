{
  self,
  root,
  lib,
  config,
  specialArgs,
  nur,
  nixos-facter-modules,
  sops-nix,
  home-manager,
  nix-index-database,
  stylix,
  perch-modules,
  ...
}:

let
  hostModule = {
    options.dot.host = {
      name = lib.mkOption {
        type = lib.types.str;
      };
      ip = lib.mkOption {
        type = lib.types.str;
      };
      user = lib.mkOption {
        type = lib.types.str;
        default = "haras";
      };
      pass = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      facterPath = lib.mkOption {
        type = lib.types.path;
        default = lib.path.append root "src/hosts/${config.dot.host.name}/hardware.json";
      };
      sopsPath = lib.mkOption {
        type = lib.types.path;
        default = lib.path.append root "src/hosts/${config.dot.host.name}/secrets.yaml";
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
        ) (builtins.attrValues self.nixosConfigurations);
      };
    };
  };
in
{
  defaultNixosModule = true;
  nixosModule = {
    imports = [
      nur.modules.nixos.default
      nixos-facter-modules.nixosModules.facter
      sops-nix.nixosModules.default
      home-manager.nixosModules.default
      stylix.nixosModules.stylix
      perch-modules.nixosModules."flake-deployRs"
      perch-modules.nixosModules."flake-rumor"
      hostModule
    ]
    ++ (builtins.attrValues (
      lib.filterAttrs (name: _: !(lib.hasPrefix "host" name) && name != "default") self.nixosModules
    ));

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
    rumor.sops = [
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
        dot.host = config.dot.host;
      }
    ]
    ++ (lib.optionals (config.dot ? hardware) [
      {
        dot.hardware = config.dot.hardware;
      }
    ]);
  };

  defaultHomeManagerModule = true;
  homeManagerModule = {
    imports = [
      nur.modules.homeManager.default
      nix-index-database.homeModules.nix-index
      nixos-facter-modules.hmModules.facter
      sops-nix.homeManagerModules.sops
    ]
    ++ (builtins.attrValues (
      lib.filterAttrs (name: _: !(lib.hasPrefix "host" name) && name != "default") self.homeManagerModules
    ));

    home.stateVersion = config.dot.host.version;

    home.username = config.dot.host.user;
    home.homeDirectory = "/home/${config.dot.host.user}";

    facter.reportPath = config.dot.host.facterPath;

    sops.defaultSopsFile = config.dot.host.sopsPath;
    sops.age.keyFile = "/root/host.scrt.key";
  };
}
