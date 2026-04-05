{ self, ... }:

let
  userCertsPath = "~/.cockroach-certs";
  userEnvPath = "${userCertsPath}/user.env";
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
      $env.DOT_COCKROACHDB_USER_ENV_PATH = "${userEnvPath}"

      ${builtins.readFile ./user.nu}
    '';
  };

  flake.nixosModules.critical-cockroachdb-user =
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

      user = config.dot.host.user;
      hostname = config.dot.host.name;

      clientCerts = builtins.replaceStrings [ "~" ] [ config.users.users.${user}.home ] userCertsPath;

      clientEnv = builtins.replaceStrings [ "~" ] [ config.users.users.${user}.home ] userEnvPath;

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

      port =
        if config.dot.cockroachdb.enable then
          builtins.toString cfg.sql.port
        else
          builtins.toString (builtins.head hosts).system.services.cockroachdb.sql.port;
    in
    lib.mkIf hasNetwork {
      sops.secrets."cockroach-${user}-ca-public" = {
        key = "cockroach-ca-public";
        path = "${clientCerts}/ca.crt";
        owner = user;
        group = user;
        mode = "0644";
      };
      sops.secrets."cockroach-${hostname}-${user}-public" = {
        path = "${clientCerts}/client.${user}.crt";
        owner = user;
        group = user;
        mode = "0644";
      };
      sops.secrets."cockroach-${hostname}-${user}-private" = {
        path = "${clientCerts}/client.${user}.key";
        owner = user;
        group = user;
        mode = "0400";
      };
      sops.secrets."cockroach-${user}-env" = {
        path = clientEnv;
        owner = user;
        group = user;
        mode = "0400";
      };

      cryl.sops.keys = [
        "cockroach-${hostname}-${user}-private"
        "cockroach-${hostname}-${user}-public"
        "cockroach-${user}-env"
      ];
      cryl.specification.imports = [
        {
          importer = "vault-file";
          arguments = {
            path = self.lib.vault.shared;
            file = "cockroach-${user}-pass";
            allow_fail = true;
          };
        }
        {
          importer = "vault-file";
          arguments = {
            path = self.lib.vault.shared;
            file = "cockroach-${user}-private";
            allow_fail = true;
          };
        }
        {
          importer = "vault-file";
          arguments = {
            path = self.lib.vault.shared;
            file = "cockroach-${user}-public";
            allow_fail = true;
          };
        }
      ];
      cryl.specification.generations = [
        {
          generator = "key";
          arguments = {
            name = "cockroach-${user}-pass";
          };
        }
        {
          generator = "cockroach-client-cert";
          arguments = {
            ca_private = "cockroach-ca-private";
            ca_public = "cockroach-ca-public";
            private = "cockroach-${user}-private";
            public = "cockroach-${user}-public";
            user = user;
            renew = true;
          };
        }
        {
          generator = "cockroach-client-cert";
          arguments = {
            ca_private = "cockroach-ca-private";
            ca_public = "cockroach-ca-public";
            private = "cockroach-${hostname}-${user}-private";
            public = "cockroach-${hostname}-${user}-public";
            user = user;
            renew = true;
          };
        }
        {
          generator = "moustache";
          arguments = {
            name = "cockroach-${user}-env";
            renew = true;
            variables = {
              COCKROACH_USER_PASS = "cockroach-${user}-pass";
            };
            template =
              let
                url =
                  "postgresql://${user}:{{COCKROACH_USER_PASS}}@${host}"
                  + ":${port}"
                  + "?sslmode=verify-full"
                  + "&sslrootcert=${clientCerts}/ca.crt"
                  + "&sslcert=${clientCerts}/client.${user}.crt"
                  + "&sslkey=${clientCerts}/client.${user}.key";
              in
              ''
                export COCKROACH_URL="${url}"

                export PGUSER="${user}"
                export PGPASSWORD="{{COCKROACH_USER_PASS}}"
                export PGHOST="${host}"
                export PGPORT="${port}"
                export PGSSLMODE="verify-full"
                export PGSSLROOTCERT="${clientCerts}/ca.crt"
                export PGSSLCERT="${clientCerts}/client.${user}.crt"
                export PGSSLKEY="${clientCerts}/client.${user}.key"
              '';
          };
        }
      ];
      cryl.specification.exports = [
        {
          exporter = "vault-file";
          arguments = {
            path = self.lib.vault.shared;
            file = "cockroach-${user}-pass";
          };
        }
        {
          exporter = "vault-file";
          arguments = {
            path = self.lib.vault.shared;
            file = "cockroach-${user}-private";
          };
        }
        {
          exporter = "vault-file";
          arguments = {
            path = self.lib.vault.shared;
            file = "cockroach-${user}-public";
          };
        }
      ];
    };
}
