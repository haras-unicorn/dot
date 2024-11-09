{ lib, host, config, ... }:

{
  options = {
    vpn.lighthouse = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = {
    system = {
      services.nebula.networks.nebula = {
        enable = true;
        isLighthouse = config.dot.vpn.lighthouse;
        cert = "/etc/nebula/host.crt";
        key = "/etc/nebula/host.key";
        ca = "/etc/nebula/ca.crt";
      };

      sops.secrets."${host}.vpn.pub" = {
        path = "/etc/nebula/host.crt";
        owner = "nebula";
        group = "nebula";
        mode = "0644";
      };
      sops.secrets."${host}.vpn" = {
        path = "/etc/nebula/host.key";
        owner = "nebula";
        group = "nebula";
        mode = "0400";
      };
      sops.secrets."ca.vpn.pub" = {
        path = "/etc/nebula/ca.crt";
        owner = "nebula";
        group = "nebula";
        mode = "0644";
      };
    };
  };
}
