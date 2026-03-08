{ self, ... }:

{
  libAttrs.test.modules.ntp =
    {
      lib,
      config,
      nodes,
      pkgs,
      ...
    }:
    let
      port = 123;
    in
    {
      options.dot.test = {
        ntp = {
          enable = lib.mkEnableOption "NTP test server";
        };
      };

      config = lib.mkIf config.dot.test.ntp.enable {
        dot.test.external = {
          ntp = {
            node = "ntp";
            protocol = "ntp";
            connection.address = nodes.ntp.dot.host.ip;
            connection.port = port;
          };
        };

        defaults =
          { config, nodes, ... }:
          lib.mkIf (config.dot.host.name != "ntp") {
            networking.timeServers = lib.mkForce [ nodes.ntp.dot.host.ip ];
          };

        dot.test.commands.prefix = lib.mkBefore ''
          ntp.wait_for_unit("chronyd.service")
        '';

        nodes.ntp = {
          services.timesyncd.enable = false;

          services.chrony = {
            enable = true;
            servers = [ ];
            initstepslew.enabled = false;
            extraConfig = ''
              local stratum 10
              allow 192.168.0.0/16
              allow ${self.dot.network.subnet.ip}/${builtins.toString self.dot.network.subnet.bits}
              port ${builtins.toString port}
              log tracking measurements statistics
            '';
          };

          systemd.services.chronyd.after = [ "network-online.target" ];
          systemd.services.chronyd.requires = [ "network-online.target" ];

          networking.firewall.allowedUDPPorts = [ port ];
        };
      };
    };
}
