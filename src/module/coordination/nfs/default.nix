{ pkgs, config, lib, ... }:

let
  hasNetwork = config.dot.hardware.network.enable;
  isCoordinator = config.dot.nfs.coordinator.enable;
in
{
  options = {
    nfs.coordinator.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf hasNetwork {
    system = {
      environment.systemPackages = [
        pkgs.seaweedfs
      ];
    };
  };
}
