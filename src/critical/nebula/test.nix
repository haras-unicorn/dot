{ self, config, ... }:

let
  subnetConfig = config.dot.network.subnet;
in
{
  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];
  perSystem =
    { pkgs, ... }:
    {
      checks.test-critical-nebula-disabled = self.lib.test.mkTest pkgs {
        name = "critical-nebula-disabled";
        dot.test.disabledService.enable = true;
        dot.test.disabledService.name = "nebula@dot.service";
        dot.test.disabledService.config = "/etc/nebula";
        dot.test.disabledService.module = {
          imports = [ self.nixosModules.critical-nebula ];
          dot.nebula.enable = false;
        };
      };

      checks.test-critical-nebula-mesh =
        let
          vlan = 1;
          vlanString = builtins.toString vlan;

          addressOffset = 10;
          addressPrefix = "192.168.${vlanString}";

          amount = 5;

          # NOTE: first we want the non-lighthouse nodes to
          # try to connect to the lighthouse
          lighthouseNumber = amount;
          lighthouseNumberString = builtins.toString lighthouseNumber;
          lighthouseNebulaAddress = "${subnetConfig.prefix}.${lighthouseNumberString}";
          isLighthouse = config: config.dot.test.clusters.number == lighthouseNumber;

          lighthouseAddressNumber = addressOffset + lighthouseNumber;
          lighthouseAddressNumberString = builtins.toString lighthouseAddressNumber;
          lighthouseAddress = "${addressPrefix}.${lighthouseAddressNumberString}";

          lighthousePort = 4242;
          lighthousePortString = builtins.toString lighthousePort;
        in
        self.lib.test.mkTest pkgs {
          name = "critical-nebula-mesh";

          dot.test.rumor.shared.specification.generations = [
            {
              generator = "yaml";
              arguments = {
                name = "nebula-lighthouse";
                value = {
                  static_host_map.${lighthouseNebulaAddress} = [
                    "${lighthouseAddress}:${lighthousePortString}"
                  ];
                  lighthouse.am_lighthouse = true;
                  relay.am_relay = true;
                  punchy = {
                    punch = true;
                    respond = true;
                  };
                };
              };
            }
            {
              generator = "yaml";
              arguments = {
                name = "nebula-non-lighthouse";
                value = {
                  static_host_map.${lighthouseNebulaAddress} = [
                    "${lighthouseAddress}:${lighthousePortString}"
                  ];
                  lighthouse.hosts = [ lighthouseNebulaAddress ];
                  relay.relays = [ lighthouseNebulaAddress ];
                  punchy = {
                    punch = true;
                    respond = true;
                  };
                };
              };
            }
          ];

          dot.test.clusters.node.amount = amount;
          dot.test.clusters.node.module =
            { lib, config, ... }:
            let
              addressNumber = addressOffset + config.dot.test.clusters.number;
              addressNumberString = builtins.toString addressNumber;
              address = "192.168.${vlanString}.${addressNumberString}";

              nebulaAddressNumber = config.dot.test.clusters.number;
              nebulaAddressNumberString = builtins.toString nebulaAddressNumber;
              nebulaAddress = "${subnetConfig.prefix}.${nebulaAddressNumberString}";
            in
            {
              imports = [
                self.nixosModules.critical-nebula
              ];

              dot.test.network.enable = false;
              virtualisation.vlans = [ vlan ];
              # NOTE: mkBefore because we want to override the default one
              networking.interfaces.eth1.ipv4.addresses = lib.mkBefore [
                {
                  inherit address;
                  prefixLength = 24;
                }
              ];

              dot.host.ip = nebulaAddress;
              dot.host.interface = "dot";

              dot.nebula.enableLighthouseAndRelay = isLighthouse config;
              # NOTE: otherwise it opens the port on all hosts
              services.nebula.networks.dot.listen.port = lib.mkIf (isLighthouse config) lighthousePort;
            };

          dot.test.commands.enable = true;
          dot.test.commands.perNode = [
            ''command_node.wait_for_unit("network-online.target")''
            ''command_node.wait_for_unit("nebula@dot.service")''
            ''command_node.wait_until_succeeds("ip link show dot")''
            ''command_node.succeed("test -f /etc/nebula/config.d/config.yaml")''
            (
              node:
              if isLighthouse node then
                ''
                  command_node.succeed(
                    "grep -q 'am_lighthouse: true' /etc/nebula/config.d/lighthouse.yaml"
                  )
                  command_node.succeed(
                    "grep -q 'port: ${lighthousePortString}' /etc/nebula/config.d/config.yaml"
                  )
                  command_node.succeed("iptables -L -n | grep -q '${lighthousePortString}'")
                ''
              else
                ''
                  command_node.succeed(
                    "grep -q 'port: 0' /etc/nebula/config.d/config.yaml"
                  )
                  command_node.fail("iptables -L -n | grep -q '${lighthousePortString}'")
                ''
            )
            (node: ''
              command_node.succeed(
                "ip addr show dot | grep -q '${node.dot.host.ip}'"
              )
            '')
            (
              { nodea, ... }:
              builtins.map (other: ''
                command_node.wait_until_succeeds("ping -c 3 ${other.dot.host.ip}", timeout=10)
              '') nodea
            )
          ];
        };

      checks.test-critical-nebula-relay = self.lib.test.mkTest pkgs {
        name = "critical-nebula-relay";

        dot.test.rumor.shared.specification.generations = [
          {
            generator = "yaml";
            arguments = {
              name = "nebula-lighthouse";
              value = {
                static_host_map."${subnetConfig.prefix}.1" = [
                  "192.168.1.10:4242"
                  "192.168.2.10:4242"
                ];
                lighthouse.am_lighthouse = true;
                relay.am_relay = true;
                punchy = {
                  punch = true;
                  respond = true;
                };
              };
            };
          }
          {
            generator = "yaml";
            arguments = {
              name = "nebula-non-lighthouse";
              value = {
                static_host_map."${subnetConfig.prefix}.1" = [
                  "192.168.1.10:4242"
                  "192.168.2.10:4242"
                ];
                lighthouse.hosts = [ "${subnetConfig.prefix}.1" ];
                relay.relays = [ "${subnetConfig.prefix}.1" ];
                punchy = {
                  punch = true;
                  respond = true;
                };
              };
            };
          }
        ];

        nodes = {
          relay = {
            imports = [
              self.nixosModules.critical-nebula
            ];

            dot.test.network.enable = false;
            virtualisation.vlans = [
              1
              2
            ];
            networking.interfaces.eth1.ipv4.addresses = [
              {
                address = "192.168.1.10";
                prefixLength = 24;
              }
            ];
            networking.interfaces.eth2.ipv4.addresses = [
              {
                address = "192.168.2.10";
                prefixLength = 24;
              }
            ];

            dot.host.ip = "${subnetConfig.prefix}.1";
            dot.host.interface = "dot";

            dot.nebula.enableLighthouseAndRelay = true;
          };

          node1 = {
            imports = [
              self.nixosModules.critical-nebula
            ];

            dot.test.network.enable = false;
            virtualisation.vlans = [ 1 ];
            networking.interfaces.eth1.ipv4.addresses = [
              {
                address = "192.168.1.20";
                prefixLength = 24;
              }
            ];

            dot.host.ip = "${subnetConfig.prefix}.11";
            dot.host.interface = "dot";

            dot.nebula.enableLighthouseAndRelay = false;
          };

          node2 = {
            imports = [
              self.nixosModules.critical-nebula
            ];

            dot.test.network.enable = false;
            virtualisation.vlans = [ 2 ];
            networking.interfaces.eth1.ipv4.addresses = [
              {
                address = "192.168.2.20";
                prefixLength = 24;
              }
            ];

            dot.host.ip = "${subnetConfig.prefix}.12";
            dot.host.interface = "dot";

            dot.nebula.enableLighthouseAndRelay = false;
          };
        };

        testScript = ''
          start_all()

          relay.wait_for_unit("network-online.target")
          node1.wait_for_unit("network-online.target")
          node2.wait_for_unit("network-online.target")

          relay.wait_for_unit("nebula@dot.service")
          node1.wait_for_unit("nebula@dot.service")
          node2.wait_for_unit("nebula@dot.service")

          relay.wait_until_succeeds("ip link show dot")
          node1.wait_until_succeeds("ip link show dot")
          node2.wait_until_succeeds("ip link show dot")

          relay.succeed("test -f /etc/nebula/config.d/config.yaml")
          relay.succeed("grep -q 'am_relay: true' /etc/nebula/config.d/lighthouse.yaml")

          node1.succeed("test -f /etc/nebula/config.d/config.yaml")
          node1.succeed("test -f /etc/nebula/config.d/lighthouse.yaml")
          node1.succeed("grep -q '${subnetConfig.prefix}.1' /etc/nebula/config.d/lighthouse.yaml")

          node2.succeed("test -f /etc/nebula/config.d/config.yaml")
          node2.succeed("test -f /etc/nebula/config.d/lighthouse.yaml")
          node2.succeed("grep -q '${subnetConfig.prefix}.1' /etc/nebula/config.d/lighthouse.yaml")

          relay.succeed("iptables -L -n | grep -q '4242'")
          node1.fail("iptables -L -n | grep -q '4242'")
          node2.fail("iptables -L -n | grep -q '4242'")

          relay.succeed("ip addr show dot | grep -q '${subnetConfig.prefix}.1'")
          node1.succeed("ip addr show dot | grep -q '${subnetConfig.prefix}.11'")
          node2.succeed("ip addr show dot | grep -q '${subnetConfig.prefix}.12'")

          node1.succeed("ping -c 3 192.168.1.10")
          node2.succeed("ping -c 3 192.168.2.10")
          relay.succeed("ping -c 3 192.168.1.20")
          relay.succeed("ping -c 3 192.168.2.20")

          node1.succeed("ping -c 3 ${subnetConfig.prefix}.1")
          node2.succeed("ping -c 3 ${subnetConfig.prefix}.1")
          relay.succeed("ping -c 3 ${subnetConfig.prefix}.11")
          relay.succeed("ping -c 3 ${subnetConfig.prefix}.12")

          node1.succeed("ping -c 3 ${subnetConfig.prefix}.12")
          node2.succeed("ping -c 3 ${subnetConfig.prefix}.11")

          node1.fail("ping -c 1 192.168.2.10 || ping -c 1 192.168.2.20")
          node2.fail("ping -c 1 192.168.1.10 || ping -c 1 192.168.1.20")
        '';
      };
    };
}
