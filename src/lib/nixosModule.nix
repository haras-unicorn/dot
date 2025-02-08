{ self, nixpkgs, ... }:

let
  sharedConfig = "${self}/src/host/config.nix";

  modules = builtins.map
    (x: self.lib.module.mkSystemModule x.__import.path)
    (builtins.filter
      (x: x.__import.type == "default")
      (nixpkgs.lib.collect
        (builtins.hasAttr "__import")
        (self.lib.import.importDirMeta "${self}/src/module")));
in
{
  mkNixosModule = host: system:
    let
      config = "${self}/src/host/${host}/config.nix";
      hardware = "${self}/src/host/${host}/hardware.json";
      secrets = "${self}/src/host/${host}/secrets.yaml";
    in
    ({ lib, user, group, uid, gid, version, ... }: {
      imports =
        modules
        ++ (if builtins.pathExists config
        then [ (self.lib.module.mkSystemModule config) ]
        else [ ])
        ++ (if builtins.pathExists sharedConfig
        then [ (self.lib.module.mkSystemModule sharedConfig) ]
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
