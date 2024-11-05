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
    in
    {
      imports =
        (builtins.map self.lib.module.mkHomeModule modules)
        ++ [ (self.lib.module.mkHomeModule config) ];

      facter.reportPath = hardware;

      home.stateVersion = version;
      home.username = "${user}";
      home.homeDirectory = "/home/${user}";
    };
}
