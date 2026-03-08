{
  flake.nixosModules.capabilities-targets = {
    systemd.targets.dot-network = {
      description = "Dot network started";
      wantedBy = [ "multi-user.target" ];
    };
    systemd.targets.dot-network-online = {
      description = "Dot network online";
      wantedBy = [ "multi-user.target" ];
    };

    systemd.targets.dot-time-synchronized = {
      description = "Dot time synchronized";
      wantedBy = [ "multi-user.target" ];
    };

    systemd.targets.dot-database-initialized = {
      description = "Dot database initialized";
      wantedBy = [ "multi-user.target" ];
    };
  };
}
