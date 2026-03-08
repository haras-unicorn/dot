{ self, ... }:

{
  flake.nixosModules.critical-cockroachdb =
    {
      lib,
      config,
      pkgs,
      utils,
      ...
    }:
    let
      hasNetwork = config.dot.hardware.network.enable;

      cfg = config.services.cockroachdb;

      certs = "/var/lib/cockroachdb/.certs";

      user = config.dot.host.user;

      hosts = builtins.map (x: x.ip) (
        builtins.filter (
          x:
          if lib.hasAttrByPath [ "system" "dot" "cockroachdb" "enable" ] x then
            x.system.dot.cockroachdb.enable
          else
            false
        ) config.dot.host.hosts
      );

      # NOTE: https://www.cockroachlabs.com/docs/stable/cockroach-start
      joinHosts = builtins.tail (lib.lists.sublist 0 5 hosts);

      initHost = builtins.head joinHosts;

      join = builtins.concatStringsSep "," (
        builtins.map (x: "${x}:${builtins.toString cfg.listen.port}") joinHosts
      );
    in
    {
      options.dot = {
        cockroachdb = {
          enable = lib.mkEnableOption "CockroachDB";
        };
      };

      config = lib.mkIf (hasNetwork && config.dot.cockroachdb.enable) {
        dot.cockroachdb.enableCa = true;

        services.cockroachdb.extraArgs = [
          "--background"
          "--logtostderr=WARNING"
          "--max-offset=5s"
        ];
        systemd.services.cockroachdb.serviceConfig.Type = lib.mkForce "forking";
        systemd.services.cockroachdb.after = [
          "dot-network-online.target"
          "dot-time-synchronized.target"
        ];
        systemd.services.cockroachdb.requires = [
          "dot-network-online.target"
          "dot-time-synchronized.target"
        ];

        services.cockroachdb.enable = true;
        services.cockroachdb.join = join;
        services.cockroachdb.openPorts = true;
        services.cockroachdb.certsDir = certs;
        services.cockroachdb.http.address = config.dot.host.ip;
        services.cockroachdb.listen.address = config.dot.host.ip;
        services.cockroachdb.listen.port = 26258;
        services.cockroachdb.sql.address = config.dot.host.ip;
        services.cockroachdb.sql.port = 26257;
        services.cockroachdb.locality =
          "region=${config.dot.locality.region}" + ",datacenter=${config.dot.locality.dataCenter}";

        services.cockroachdb.init.enable = true;
        services.cockroachdb.init.runner = config.dot.host.ip == initHost;
        services.cockroachdb.init.hash = self.narHash;
        services.cockroachdb.init.sql.files = lib.mkBefore [ config.sops.secrets."cockroach-init".path ];
        systemd.targets.dot-database-initialized = {
          requires = [ "cockroachdb-initialization.service" ];
          after = [ "cockroachdb-initialization.service" ];
        };

        dot.database = {
          host = cfg.sql.address;
          port = cfg.sql.port;
          protocol = "postgresql://";
        };

        dot.services = [
          {
            name = "cockroachdb";
            port = cfg.http.port;
            tls = true;
            health = "https:///health";
          }
        ];

        environment.systemPackages = [
          pkgs.cockroachdb
          pkgs.postgresql
        ];

        programs.rust-motd.settings = {
          service_status = {
            CockroachDB = "cockroachdb";
          };
        };

        sops.secrets."cockroach-public" = {
          path = "${certs}/node.crt";
          owner = config.services.cockroachdb.user;
          group = config.services.cockroachdb.group;
          mode = "0644";
        };
        sops.secrets."cockroach-private" = {
          path = "${certs}/node.key";
          owner = config.services.cockroachdb.user;
          group = config.services.cockroachdb.group;
          mode = "0400";
        };
        sops.secrets."cockroach-init" = {
          owner = config.services.cockroachdb.user;
          group = config.services.cockroachdb.group;
          mode = "0400";
        };

        rumor.sops.keys = [
          "cockroach-private"
          "cockroach-public"
          "cockroach-init"
        ];
        rumor.specification.generations = [
          {
            generator = "moustache";
            arguments = {
              name = "cockroach-init";
              renew = true;
              variables = {
                COCKROACH_ROOT_PASS = "cockroach-root-pass";
                COCKROACH_USER_PASS = "cockroach-${user}-pass";
              };
              template = ''
                alter user root with password '{{COCKROACH_ROOT_PASS}}';


                create user if not exists ${user} password '{{COCKROACH_USER_PASS}}';

                create database if not exists ${user};

                use ${user};

                alter default privileges for all roles in schema public grant all on tables to ${user};
                alter default privileges for all roles in schema public grant all on sequences to ${user};
                alter default privileges for all roles in schema public grant all on functions to ${user};

                grant all on all tables in schema public to ${user};
                grant all on all sequences in schema public to ${user};
                grant all on all functions in schema public to ${user};

                reset database;
              '';
            };
          }
          {
            generator = "cockroach-node-cert";
            arguments = {
              ca_private = "cockroach-ca-private";
              ca_public = "cockroach-ca-public";
              hosts = [
                "localhost"
                "127.0.0.1"
                config.dot.host.ip
                "cockroachdb.${config.dot.domains.service}"
              ];
              private = "cockroach-private";
              public = "cockroach-public";
              renew = true;
            };
          }
        ];
      };
    };
}
