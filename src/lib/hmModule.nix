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
    in
    {
      imports =
        (builtins.map self.lib.module.mkHomeSharedModule modules)
        ++ [ (self.lib.module.mkHomeSharedModule config) ];

      home.stateVersion = version;
      home.username = "${user}";
      home.homeDirectory = "/home/${user}";
    };
}
