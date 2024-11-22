{ self, ... }:

let
  user = self.lib.nixosConfiguration.user;
  version = self.lib.nixosConfiguration.version;
  modules = self.lib.nixosConfiguration.modules;

  sharedConfig = "${self}/src/host/config.nix";
in
{
  mkNixosModule = host: system:
    let
      config = import "${self}/src/host/${host}/config.nix";
      hardware = "${self}/src/host/${host}/hardware.json";
      secrets = "${self}/src/host/${host}/secrets.yaml";
    in
    ({ lib, ... }: {
      imports =
        (builtins.map self.lib.module.mkSystemModule modules)
        ++ (if builtins.pathExists config
        then [ (self.lib.module.mkSystemModule (import config)) ]
        else [ ])
        ++ (if builtins.pathExists sharedConfig
        then [ (self.lib.module.mkSystemModule (import sharedConfig)) ]
        else [ ])
        ++ [{ dot = self.lib.scripts.parseFile "${self}/src/host/${host}"; }]
        ++ [{ dot = self.lib.scripts.parseFile "${self}/src/host"; }]
      ;

      options = {
        dot.scripts = lib.mkOption {
          type = lib.types.raw;
        };
      };

      config = {
        dot.scripts = self.lib.scripts.parseDir "${self}/src/host";

        facter.reportPath = hardware;

        sops.defaultSopsFile = secrets;
        sops.age.keyFile = "/root/host.scrt.key";

        networking.hostName = host;
        system.stateVersion = version;

        users.mutableUsers = false;
        users.users."${user}" = {
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
