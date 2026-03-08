{ self, ... }:

{
  libAttrs.test.modules.dns =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    let
      testConfig = config;

      port = 53;
    in
    {
      options.dot.test = {
        dns = {
          enable = lib.mkEnableOption "DNS test server";
          zones = lib.mkOption {
            type = lib.types.attrsOf (lib.types.attrsOf lib.types.str);
            default = { };
            description = "Local DNS zones to serve as local-data entries";
            example = {
              "test.local" = {
                "test.local" = "192.168.1.100";
                "www.test.local" = "192.168.1.100";
              };
            };
          };
        };
      };

      config = lib.mkIf testConfig.dot.test.dns.enable {
        dot.test.external.dns = {
          node = "dns";
          protocol = "dns";
          connection = {
            address = testConfig.nodes.dns.dot.host.ip;
            port = port;
          };
        };

        defaults =
          { config, nodes, ... }:
          lib.mkIf (config.dot.host.name != "dns") {
            networking.nameservers = lib.mkForce [ nodes.dns.dot.host.ip ];
          };

        dot.test.commands.prefix = lib.mkBefore ''
          dns.wait_for_unit("unbound.service")
        '';

        nodes.dns =
          { config, ... }:
          {
            services.unbound = {
              enable = true;
              settings = {
                server = lib.mkMerge [
                  {
                    interface = [ "0.0.0.0" ];
                    port = port;
                    access-control = [
                      "192.168.0.0/16 allow"
                      "${self.dot.network.subnet.ip}/${builtins.toString self.dot.network.subnet.bits} allow"
                    ];
                  }
                  (lib.mkIf (testConfig.dot.test.dns.zones != { }) {
                    "local-zone" = lib.mapAttrsToList (name: _: "${name} static") testConfig.dot.test.dns.zones;
                    "local-data" = lib.flatten (
                      lib.mapAttrsToList (
                        zone: records: lib.mapAttrsToList (name: ip: "\"${name}. A ${ip}\"") records
                      ) testConfig.dot.test.dns.zones
                    );
                  })
                ];
              };
            };

            networking.firewall.allowedUDPPorts = [ port ];
            networking.firewall.allowedTCPPorts = [ port ];
          };
      };
    };
}
