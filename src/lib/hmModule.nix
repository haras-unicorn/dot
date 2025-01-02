{ self, nixpkgs, ... }:

let
  sharedConfig = "${self}/src/host/config.nix";

  user = self.lib.nixosConfiguration.user;
  version = self.lib.nixosConfiguration.version;

  modules = builtins.map
    (x: self.lib.module.mkHomeModule x.__import.path)
    (builtins.filter
      (x: x.__import.type == "default")
      (nixpkgs.lib.collect
        (builtins.hasAttr "__import")
        (self.lib.import.importDirMeta "${self}/src/module")));
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
        modules
        ++ (if builtins.pathExists config
        then [ (self.lib.module.mkHomeModule (import config)) ]
        else [ ])
        ++ (if builtins.pathExists sharedConfig
        then [ (self.lib.module.mkHomeModule (import sharedConfig)) ]
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

        home.stateVersion = version;
        home.username = "${user}";
        home.homeDirectory = "/home/${user}";
      };
    });
}
