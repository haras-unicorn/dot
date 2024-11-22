{ host, config, lib, ... }:

let
  hasNetwork = config.dot.hardware.network.enable;
  rootDomain = "s3.garage";
in
{
  options = {
    nfs.coordinator = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    nfs.node = lib.mkOption {
      type = lib.types.str;
      default = false;
    };
  };

  config = lib.mkIf hasNetwork {
    system = {
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
        rpc_bind_addr = "[::]:3900";
        rpc_bind_outgoing = true;
        rpc_public_addr = "";
        bootstrap_peers = [
          ""
        ];
        admin = {
          api_bind_addr = "localhost:3901";
        };
        s3_api = {
          api_bind_addr = "localhost:3902";
          s3_region = "garage";
          root_domain = rootDomain;
        };
        s3_web = {
          bind_addr = "localhost:3902";
          root_domain = rootDomain;
        };
      };
    };
  };
}
