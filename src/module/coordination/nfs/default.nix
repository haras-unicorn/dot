{ host, config, lib, ... }:

let
  rootDomain = "s3.garage";

  hasNetwork = config.dot.hardware.network.enable;
  hasMonitor = config.dot.hardware.monitor.enable;

  ip = config.dot.vpn.ip;
  rpcPort = 3900;
  adminPort = rpcPort + 1;

  isCoordinator = config.dot.nfs.coordinator;
  bindAddr = if isCoordinator then ip else "localhost";
in
{
  options = {
    nfs.coordinator = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    nfs.node = lib.mkOption {
      type = lib.types.strMatching "[a-z0-9]+";
      default = false;
    };
    nfs.rpcPort = lib.mkOption {
      type = lib.types.ints.u16;
      default = false;
    };
  };

  config = {
    system = lib.mkIf hasNetwork {
      services.garage.enable = true;
      services.garage.environmentFile = "/etc/garage/host.env";
      sops.secrets."${host}.nfs" = {
        path = "/etc/garage/host.env";
        owner = "garage";
        group = "garage";
        mode = "0400";
      };
      services.garage.settings = {
        replication_factor = 2;
        db_engine = "sqlite";
        metadata_fsync = true;
        data_fsync = true;
        rpc_bind_addr = "${ip}:${builtins.toString rpcPort}";
        rpc_bind_outgoing = true;
        rpc_public_addr = "${ip}:${builtins.toString rpcPort}";
        bootstrap_peers = builtins.map
          (other: "${other.nfs.node}@${other.vpn.ip}:${builtins.toString rpcPort}")
          config.dot.others;
        admin = {
          api_bind_addr = "${bindAddr}:${builtins.toString adminPort}";
        };
        s3_api = {
          api_bind_addr = "${bindAddr}:${builtins.toString (rpcPort + 1)}";
          s3_region = "garage";
          root_domain = rootDomain;
        };
        s3_web = {
          bind_addr = "${bindAddr}:${builtins.toString (rpcPort + 1)}";
          root_domain = rootDomain;
        };
      };
    };

    home = lib.mkIf hasNetwork {
      xdg.desktopEntries = lib.mkIf hasMonitor {
        garage = {
          name = "Garage";
          exec = "${config.dot.browser.package}/bin/${config.dot.browser.bin} --new-window localhost:${builtins.toString adminPort}";
          terminal = false;
        };
      };
    };
  };
}
