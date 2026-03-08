{ self, ... }:

{
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

      port =
        if config.dot.cockroachdb.enable then
          builtins.toString cfg.sql.port
        else
          builtins.toString (builtins.head hosts).system.services.cockroachdb.sql.port;
    in
    {
      options.dot = {
        cockroachdb = {
          enableRootConnection = lib.mkEnableOption "CockroachDB root connection";
        };
      };

      config = lib.mkIf (hasNetwork && config.dot.cockroachdb.enableRootConnection) {
        dot.cockroachdb.enableCa = true;

        environment.systemPackages = [
          (pkgs.writeShellApplication {
            name = "dot-cockroach-root";
            runtimeInputs = [ pkgs.cockroachdb ];
            text = ''
              if [[ "$USER" != "root" ]]; then
                echo "This wrapper requires being ran by root."
                exit 1
              fi
              # shellcheck disable=SC1091
              source ${config.sops.secrets."cockroach-root-env".path}
              exec cockroach "$@"
            '';
          })
        ];

        sops.secrets."cockroach-root-public" = {
          path = "${certs}/client.root.crt";
          owner = config.services.cockroachdb.user;
          group = config.services.cockroachdb.group;
          mode = "0644";
        };
        sops.secrets."cockroach-root-private" = {
          path = "${certs}/client.root.key";
          owner = config.services.cockroachdb.user;
          group = config.services.cockroachdb.group;
          mode = "0400";
        };
        sops.secrets."cockroach-root-env" = {
          owner = config.services.cockroachdb.user;
          group = config.services.cockroachdb.group;
          mode = "0400";
        };

        rumor.sops.keys = [
          "cockroach-root-private"
          "cockroach-root-public"
          "cockroach-root-env"
        ];
        rumor.specification.imports = [
          {
            importer = "vault-file";
            arguments = {
              path = self.lib.rumor.shared;
              file = "cockroach-root-pass";
              allow_fail = true;
            };
          }
        ];
        rumor.specification.generations = [
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
                  export COCKROACH_URL="${url}"

                  export PGUSER="root"
                  export PGPASSWORD="{{COCKROACH_ROOT_PASS}}"
                  export PGHOST="${host}"
                  export PGPORT="${port}"
                  export PGSSLMODE="verify-full"
                  export PGSSLROOTCERT="${certs}/ca.crt"
                  export PGSSLCERT="${certs}/client.root.crt"
                  export PGSSLKEY="${certs}/client.root.key"
                '';
            };
          }
        ];
        rumor.specification.exports = [
          {
            exporter = "vault-file";
            arguments = {
              path = self.lib.rumor.shared;
              file = "cockroach-root-pass";
            };
          }
        ];
      };
    };
}
