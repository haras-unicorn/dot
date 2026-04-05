{
  libAttrs.test.nixosModules.host =
    {
      lib,
      config,
      nodes,
      pkgs,
      ...
    }:
    {
      options.dot.test = {
        network = {
          enable = lib.mkEnableOption "Test network";
        };
      };

      config = lib.mkMerge [
        ({ dot.test.network.enable = lib.mkDefault true; })
        (lib.mkIf config.dot.test.network.enable (
          let
            ip = "192.168.1.${builtins.toString (9 + config.virtualisation.test.nodeNumber)}";
          in
          {
            dot.host.ip = lib.mkDefault ip;
            dot.host.interface = lib.mkDefault "eth1";
            virtualisation.vlans = [ 1 ];
            # NOTE: mkBefore because we want to override the default one
            networking.interfaces.eth1.ipv4.addresses = lib.mkBefore [
              {
                address = config.dot.host.ip;
                prefixLength = 24;
              }
            ];
          }
        ))
        {
          dot.host.user = "haras";
          dot.host.group = "haras";
          dot.host.uid = 1000;
          dot.host.gid = 1000;
          dot.host.home = "/home/haras";
          dot.host.pass = lib.mkDefault true;
          dot.host.version = "24.11";
          users.groups.${config.dot.host.group} = {
            gid = config.dot.host.gid;
          };
          users.users.${config.dot.host.user} = {
            uid = config.dot.host.uid;
            group = config.dot.host.group;
            isNormalUser = true;
            home = config.dot.host.home;
            createHome = true;
          };

          dot.host.name = config.virtualisation.test.nodeName;
          dot.host.hosts = builtins.map (
            node:
            node.dot.host
            // {
              system = node;
            }
          ) (builtins.attrValues nodes);

          dot.hardware.network.enable = true;

          dot.hardware.threads = config.virtualisation.cores;
          dot.hardware.memory = config.virtualisation.memorySize * 1024 * 1024;

          networking.hostName = config.dot.host.name;

          virtualisation.memorySize = 8192; # in MiB
          virtualisation.cores = 4;
          virtualisation.graphics = false;

          # Workaround for nixpkgs gzip/install-info issue
          documentation.info.enable = false;

          system.stateVersion = config.dot.host.version;

          environment.systemPackages = [
            pkgs.curl
            pkgs.jq
            pkgs.dig
          ];
        }
      ];
    };
}
