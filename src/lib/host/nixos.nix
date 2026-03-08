{
  specialArgs,
  inputs,
  root,
  ...
}:

{
  libAttrs.host.modules.nixos.nixos =
    { lib, config, ... }:
    {
      imports = [
        inputs.nur.modules.nixos.default
        inputs.nixos-facter-modules.nixosModules.facter
        inputs.sops-nix.nixosModules.default
        inputs.home-manager.nixosModules.default
        inputs.stylix.nixosModules.stylix
      ];

      system.stateVersion = config.dot.host.version;

      facter.reportPath = config.dot.host.hardware;

      networking.hostName = config.dot.host.name;

      deploy.node = {
        hostname = config.dot.host.ip;
        sshUser = config.dot.host.user;
      };

      sops.defaultSopsFile = config.dot.host.secrets;
      sops.age.keyFile = "/root/host.scrt.key";
      # FIXME: assumes we're running cryl in some subdir of the repository
      cryl.sops.path = "../${lib.path.removePrefix root config.dot.host.secrets}";
      cryl.specification = {
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
      cryl.sops.keys = [
        "pass-pub"
      ];
      cryl.specification.generations = [
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
        {
          dot.host.ip = config.dot.host.ip;
          dot.host.interface = config.dot.host.interface;
          dot.host.name = config.dot.host.name;
          dot.host.hardware = config.dot.host.hardware;
          dot.host.secrets = config.dot.host.secrets;
        }
      ];
    };
}
