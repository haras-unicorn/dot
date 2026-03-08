{
  libAttrs.test.nixosModules.targets =
    { lib, ... }:
    {
      systemd.targets.dot-network-online = {
        requires = [ "network-online.target" ];
        after = [ "network-online.target" ];
      };
      systemd.targets.dot-time-synchronized = {
        requires = [ "network-online.target" ];
        after = [ "network-online.target" ];
      };
      systemd.targets.dot-database-initialized = {
        requires = [ "network-online.target" ];
        after = [ "network-online.target" ];
      };
      systemd.targets.dot-filesystem-initialized = {
        requires = [ "network-online.target" ];
        after = [ "network-online.target" ];
      };
    };
}
