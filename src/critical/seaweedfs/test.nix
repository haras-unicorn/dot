{ self, ... }:

{
  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];

  perSystem =
    { pkgs, ... }:
    {
      checks.test-critical-seaweedfs-disabled = self.lib.test.mkTest pkgs {
        name = "critical-seaweedfs-disabled";
        dot.test.disabledService.module = { };
        dot.test.disabledService.enable = true;
        dot.test.disabledService.name = "seaweedfs.service";
        dot.test.disabledService.config = "/etc/seaweedfs";
      };

      checks.test-critical-seaweedfs-cluster = self.lib.test.mkTest pkgs {
        name = "critical-seaweedfs-cluster";
        dot.test.clusters.node.amount = 3;
        dot.test.clusters.node.module = {
          dot.test.cockroachdb.enable = true;
          dot.test.seaweedfs.enable = true;
        };
        dot.test.commands.enable = true;
        dot.test.commands.perNode = [
          ''command_node.wait_for_unit("seaweedfs-master.service", timeout=60)''
          ''command_node.wait_for_unit("seaweedfs-volume@dot.service", timeout=60)''
          ''command_node.wait_for_unit("seaweedfs-filer@dot.service", timeout=180)''
          (node: ''
            command_node.wait_until_succeeds("""
              curl -f http://${node.dot.host.ip}:9333/cluster/status
            """, timeout=60)
          '')
          (node: ''
            command_node.wait_until_succeeds("""
              curl -f http://${node.dot.host.ip}:8888/
            """, timeout=60)
          '')
          (node: ''
            command_node.succeed("""
              curl -f http://${node.dot.host.ip}:8081/status | \
                grep -q 'Version'
            """)
          '')
          (
            { node, nodea, ... }:
            builtins.map (
              other:
              # NOTE: it lists only peers but not itself
              if other.dot.host.ip == node.dot.host.ip then
                ""
              else
                ''
                  command_node.succeed("""
                    curl -f http://${node.dot.host.ip}:9333/cluster/status | \
                      grep -q '${other.dot.host.ip}'
                  """)
                ''
            ) nodea
          )
        ];
        dot.test.commands.suffix = ''
          node1.succeed("""
            echo 'Hello from SeaweedFS cluster test' \
              > /tmp/testfile.txt
          """)

          node1.succeed("""
            curl -F file=@/tmp/testfile.txt http://192.168.1.10:8888/testfolder/
          """)

          node2.wait_until_succeeds("""
            curl -f http://192.168.1.11:8888/testfolder/testfile.txt | \
              grep 'Hello from SeaweedFS cluster test'
          """, timeout=60)
          node3.wait_until_succeeds("""
            curl -f http://192.168.1.12:8888/testfolder/testfile.txt | \
              grep 'Hello from SeaweedFS cluster test'
          """, timeout=60)
          node1.succeed("""
            curl -f http://192.168.1.10:8888/testfolder/ | \
              grep 'testfile.txt'
          """)
        '';
      };
    };
}
