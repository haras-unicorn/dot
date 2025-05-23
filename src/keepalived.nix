{ config, lib, ... }:

let
  hasNetwork = config.dot.hardware.network.enable;
  networkInterface = config.dot.hardware.network.interface;

  cfg = config.dot.vip;

  peers = builtins.filter
    (host: host.locality == cfg.locality && host.lanIp != cfg.lanIp)
    (builtins.map
      (host: host.system.dot.vip)
      (builtins.filter
        (x:
          if lib.hasAttrByPath [ "system" "dot" "keepalived" "coordinator" ] x
          then x.system.dot.vip.coordinator
          else false)
        config.dot.hosts));
  peerLanIps = builtins.map (peer: peer.lanIp) peers;
in
{
  branch.nixosModule.nixosModule = {
    options.dot.vip = {
      coordinator = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };

      vip = lib.mkOption {
        type = lib.types.str;
      };

      lanIp = lib.mkOption {
        type = lib.types.str;
      };

      virtualRouterId = lib.mkOption {
        type = lib.types.int;
      };

      locality = lib.mkOption {
        type = lib.types.str;
      };
    };

    config = lib.mkIf (hasNetwork && cfg.coordinator) {
      services.keepalived.enable = true;
      # NOTE: vv fails with 'extraCommands is incompatible with the nftables based firewall'
      # services.keepalived.openFirewall = true;
      networking.firewall.extraInputRules = ''
        ip protocol vrrp accept comment "keepalived VRRP"
        ip protocol ah accept comment "keepalived AH"
        ip6 nexthdr vrrp accept comment "keepalived VRRP IPv6"  
        ip6 nexthdr ah accept comment "keepalived AH IPv6"
      '';
      services.keepalived.secretFile =
        config.sops.secrets."keepalived-secret-file".path;
      services.keepalived.vrrpInstances."VIP_${builtins.toString cfg.virtualRouterId}" = {
        state = "BACKUP";
        interface = networkInterface;
        virtualRouterId = cfg.virtualRouterId;
        priority = 100;

        unicastSrcIp = cfg.lanIp;
        unicastPeers = peerLanIps;
        virtualIps = [{ addr = cfg.vip; }];

        extraConfig = ''
          authentication {
            auth_type PASS
            auth_pass ''${KEEPALIVED_PASS}
          }
        '';
      };

      sops.secrets."keepalived-secret-file" = { };

      rumor.sops = [
        "keepalived-secret-file"
      ];
      rumor.specification.imports = [
        {
          importer = "vault-file";
          arguments = {
            path = "kv/dot/shared";
            file = "keepalived-${cfg.locality}-pass";
            allow_fail = true;
          };
        }
      ];
      rumor.specification.generations = [
        {
          generator = "key";
          arguments = {
            name = "keepalived-${cfg.locality}-pass";
          };
        }
        {
          generator = "env";
          arguments = {
            name = "keepalived-secret-file";
            variables = {
              KEEPALIVED_PASS = "keepalived-${cfg.locality}-pass";
            };
          };
        }
      ];
      rumor.specification.exports = [
        {
          exporter = "vault-file";
          arguments = {
            path = "kv/dot/shared";
            file = "keepalived-${cfg.locality}-pass";
          };
        }
      ];
    };
  };
}
