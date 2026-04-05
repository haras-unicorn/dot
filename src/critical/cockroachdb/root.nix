{ self, ... }:

let
  rootEnvPath = "/etc/cockroachdb/root.env";
in
{
  dot.cli = {
    makeRuntimeInputs = [
      (pkgs: [
        pkgs.cockroachdb
        pkgs.vault
      ])
    ];
    text = ''
      $env.DOT_COCKROACHDB_ROOT_ENV_PATH = "${rootEnvPath}"

      ${builtins.readFile ./root.nu}
    '';
  };

  flake.nixosModules.critical-cockroachdb-root =
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

      hosts = builtins.filter (
        host:
        if lib.hasAttrByPath [ "system" "dot" "cockroachdb" "enable" ] host then
          host.system.dot.cockroachdb.enable
        else
          false
      ) config.dot.host.hosts;

      host =
        if config.dot.cockroachdb.enable then
          cfg.sql.address
        else
          (builtins.head hosts).system.services.cockroachdb.sql.address;

      hostname = config.dot.host.name;

      port =
        if config.dot.cockroachdb.enable then
          builtins.toString cfg.sql.port
        else
          builtins.toString (builtins.head hosts).system.services.cockroachdb.sql.port;
    in
    lib.mkIf hasNetwork {
      sops.secrets."cockroach-root-${hostname}-public" = {
        path = "${certs}/client.root.crt";
        owner = config.services.cockroachdb.user;
        group = config.services.cockroachdb.group;
        mode = "0644";
      };
      sops.secrets."cockroach-root-${hostname}-private" = {
        path = "${certs}/client.root.key";
        owner = config.services.cockroachdb.user;
        group = config.services.cockroachdb.group;
        mode = "0400";
      };
      sops.secrets."cockroach-root-env" = {
        path = rootEnvPath;
        owner = "root";
        group = "root";
        mode = "0400";
      };

      cryl.sops.keys = [
        "cockroach-root-${hostname}-private"
        "cockroach-root-${hostname}-public"
        "cockroach-root-env"
      ];
      cryl.specification.imports = [
        {
          importer = "vault-file";
          arguments = {
            path = self.lib.vault.shared;
            file = "cockroach-root-pass";
            allow_fail = true;
          };
        }
        {
          importer = "vault-file";
          arguments = {
            path = self.lib.vault.shared;
            file = "cockroach-root-private";
            allow_fail = true;
          };
        }
        {
          importer = "vault-file";
          arguments = {
            path = self.lib.vault.shared;
            file = "cockroach-root-public";
            allow_fail = true;
          };
        }
      ];
      cryl.specification.generations = [
        {
          generator = "key";
          arguments = {
            name = "cockroach-root-pass";
          };
        }
        {
          generator = "cockroach-client-cert";
          arguments = {
            ca_private = "cockroach-ca-private";
            ca_public = "cockroach-ca-public";
            private = "cockroach-root-private";
            public = "cockroach-root-public";
            user = "root";
          };
        }
        {
          generator = "cockroach-client-cert";
          arguments = {
            ca_private = "cockroach-ca-private";
            ca_public = "cockroach-ca-public";
            private = "cockroach-root-${hostname}-private";
            public = "cockroach-root-${hostname}-public";
            user = "root";
          };
        }
        {
          generator = "moustache";
          arguments = {
            name = "cockroach-root-env";
            renew = true;
            variables = {
              COCKROACH_ROOT_PASS = "cockroach-root-pass";
            };
            template =
              let
                url =
                  "postgresql://root:{{COCKROACH_ROOT_PASS}}@${host}"
                  + ":${port}"
                  + "?sslmode=verify-full"
                  + "&sslrootcert=${certs}/ca.crt"
                  + "&sslcert=${certs}/client.root.crt"
                  + "&sslkey=${certs}/client.root.key";
              in
              ''
                COCKROACH_URL="${url}"

                PGUSER="root"
                PGPASSWORD="{{COCKROACH_ROOT_PASS}}"
                PGHOST="${host}"
                PGPORT="${port}"
                PGSSLMODE="verify-full"
                PGSSLROOTCERT="${certs}/ca.crt"
                PGSSLCERT="${certs}/client.root.crt"
                PGSSLKEY="${certs}/client.root.key"
              '';
          };
        }
      ];
      cryl.specification.exports = [
        {
          exporter = "vault-file";
          arguments = {
            path = self.lib.vault.shared;
            file = "cockroach-root-pass";
          };
        }
        {
          exporter = "vault-file";
          arguments = {
            path = self.lib.vault.shared;
            file = "cockroach-root-private";
          };
        }
        {
          exporter = "vault-file";
          arguments = {
            path = self.lib.vault.shared;
            file = "cockroach-root-public";
          };
        }
      ];
    };
}
