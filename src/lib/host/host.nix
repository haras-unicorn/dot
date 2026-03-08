{
  self,
  ...
}:

let
  hostModule =
    { lib, ... }:
    {
      dot.host = {
        user = "haras";
        group = "haras";
        uid = 1000;
        gid = 1000;
        home = "/home/haras";
        pass = lib.mkDefault true;
        version = "24.11";
        hosts = builtins.map (
          x:
          x.config.dot.host
          // {
            system = x.config;
          }
        ) (builtins.attrValues self.nixosConfigurations);
      };
    };
in
{
  libAttrs.host.modules.nixos.host = hostModule;

  libAttrs.host.modules.home.host = hostModule;
}
