{ self, ... }:

let
  user = self.lib.nixosConfiguration.user;
  version = self.lib.nixosConfiguration.version;
  modules = self.lib.nixosConfiguration.modules;

  sharedConfig = "${self}/src/host/config.nix";
in
{
  mkHmModule = host: system:
    let
      config = "${self}/src/host/${host}/config.nix";
      hardware = "${self}/src/host/${host}/hardware.json";
      secrets = "${self}/src/host/${host}/secrets.yaml";
    in
    ({ lib, ... }: {
      imports =
        (builtins.map self.lib.module.mkHomeModule modules)
        ++ (if builtins.pathExists config
        then [ (self.lib.module.mkHomeModule (import config)) ]
        else [ ])
        ++ (if builtins.pathExists sharedConfig
        then [ (self.lib.module.mkHomeModule (import sharedConfig)) ]
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

        home.stateVersion = version;
        home.username = "${user}";
        home.homeDirectory = "/home/${user}";
      };
    });
}
