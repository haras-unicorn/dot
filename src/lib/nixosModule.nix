{ self, ... }:

let
  user = self.lib.nixosConfiguration.user;
  group = self.lib.nixosConfiguration.group;
  uid = self.lib.nixosConfiguration.uid;
  gid = self.lib.nixosConfiguration.gid;
  version = self.lib.nixosConfiguration.version;
  mkModules = self.lib.nixosConfiguration.mkModules;

  sharedConfig = "${self}/src/host/config.nix";
in
{
  mkNixosModule = host: system:
    let
      config = "${self}/src/host/${host}/config.nix";
      hardware = "${self}/src/host/${host}/hardware.json";
      secrets = "${self}/src/host/${host}/secrets.yaml";
    in
    ({ lib, ... }: {
      imports =
        (mkModules self.lib.module.mkSystemModule)
        ++ (if builtins.pathExists config
        then [ (self.lib.module.mkSystemModule (import config)) ]
        else [ ])
        ++ (if builtins.pathExists sharedConfig
        then [ (self.lib.module.mkSystemModule (import sharedConfig)) ]
        else [ ])
        ++ [{ dot = self.lib.static.parseFile "${self}/src/host/${host}"; }]
        ++ [{ dot = self.lib.static.parseFile "${self}/src/host"; }]
      ;

      options = {
        dot.static = lib.mkOption {
          type = lib.types.raw;
        };
      };

      config = {
        dot.static = self.lib.static.parseDir "${self}/src/host";

        facter.reportPath = hardware;

        sops.defaultSopsFile = secrets;
        sops.age.keyFile = "/root/host.scrt.key";

        networking.hostName = host;
        system.stateVersion = version;

        users.mutableUsers = false;
        users.groups.${group} = {
          inherit gid;
        };
        users.users.${user} = {
          inherit uid;
          home = "/home/${user}";
          createHome = true;
          isNormalUser = true;
          initialPassword = user;
          extraGroups = [ "wheel" ];
          useDefaultShell = true;
        };
      };
    });
}
