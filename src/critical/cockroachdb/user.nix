{ self, ... }:

{
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

      clientCerts = "${config.users.users.${user}.home}/.cockroach-certs";

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
    {
      options.dot = {
        cockroachdb = {
          enableUserConnection = lib.mkEnableOption "CockroachDB user connection";
        };
      };

      config = lib.mkIf (hasNetwork && config.dot.cockroachdb.enableUserConnection) {
        dot.cockroachdb.enableCa = true;

        environment.systemPackages = [
          (pkgs.writeShellApplication {
            name = "dot-cockroach-${user}";
            runtimeInputs = [ pkgs.cockroachdb ];
            text = ''
              if [[ "$USER" != "${user}" ]]; then
                echo "This wrapper requires being ran by ${user}."
                exit 1
              fi
              # shellcheck disable=SC1091
              source ${config.sops.secrets."cockroach-${user}-env".path}
              exec cockroach "$@"
            '';
          })
        ];

        sops.secrets."cockroach-${user}-ca-public" = {
          key = "cockroach-ca-public";
          path = "${clientCerts}/ca.crt";
          owner = user;
          group = user;
          mode = "0644";
        };
        sops.secrets."cockroach-${user}-public" = {
          path = "${clientCerts}/client.${user}.crt";
          owner = user;
          group = user;
          mode = "0644";
        };
        sops.secrets."cockroach-${user}-private" = {
          path = "${clientCerts}/client.${user}.key";
          owner = user;
          group = user;
          mode = "0400";
        };
        sops.secrets."cockroach-${user}-env" = {
          owner = user;
          group = user;
          mode = "0400";
        };

        rumor.sops.keys = [
          "cockroach-${user}-private"
          "cockroach-${user}-public"
          "cockroach-${user}-env"
        ];
        rumor.specification.imports = [
          {
            importer = "vault-file";
            arguments = {
              path = self.lib.rumor.shared;
              file = "cockroach-${user}-pass";
              allow_fail = true;
            };
          }
        ];
        rumor.specification.generations = [
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
        rumor.specification.exports = [
          {
            exporter = "vault-file";
            arguments = {
              path = self.lib.rumor.shared;
              file = "cockroach-${user}-pass";
            };
          }
        ];
      };
    };
}
