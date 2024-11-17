{ self, ... }:

let
  user = self.lib.nixosConfiguration.user;
  version = self.lib.nixosConfiguration.version;
  modules = self.lib.nixosConfiguration.modules;
in
{
  mkHmModule = host: system:
    let
      config = import "${self}/src/host/${host}/config.nix";
      hardware = "${self}/src/host/${host}/hardware.json";
      scripts = "${self}/src/host/${host}/scripts.json";
    in
    {
      imports =
        (builtins.map self.lib.module.mkHomeModule modules)
        ++ [ (self.lib.module.mkHomeModule config) ]
        ++ (if builtins.pathExists scripts
        then [ (self.lib.scripts.mkHomeModule scripts) ]
        else [ ]);

      facter.reportPath = hardware;

      home.stateVersion = version;
      home.username = "${user}";
      home.homeDirectory = "/home/${user}";
    };
}
