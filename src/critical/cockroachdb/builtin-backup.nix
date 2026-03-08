{ self, ... }:

{
  flake.nixosModules.critical-cockroachdb-builtin-backup =
    {
      lib,
      config,
      pkgs,
      utils,
      ...
    }:
    let
      hasNetwork = config.dot.hardware.network.enable;
    in
    {
      options.dot = {
        cockroachdb = {
          enableBuiltinBackup = lib.mkEnableOption "CockroachDB automatic backup";
        };
      };

      config =
        lib.mkIf (hasNetwork && config.dot.cockroachdb.enable && config.dot.cockroachdb.enableBuiltinBackup)
          {
            services.cockroachdb.init.sql.files = [ config.sops.secrets."cockroach-backup-init".path ];

            sops.secrets."cockroach-backup-init" = {
              owner = config.services.cockroachdb.user;
              group = config.services.cockroachdb.group;
              mode = "0400";
            };

            rumor.sops.keys = [
              "cockroach-backup-init"
            ];
            rumor.specification.imports = [
              {
                importer = "vault-file";
                arguments = {
                  path = self.lib.rumor.shared;
                  file = "cockroach-backup-pass";
                  allow_fail = true;
                };
              }
              {
                importer = "vault-file";
                arguments = {
                  path = self.lib.rumor.shared;
                  file = "cloudflare-r2-cockroachdb-endpoint";
                };
              }
              {
                importer = "vault-file";
                arguments = {
                  path = self.lib.rumor.shared;
                  file = "cloudflare-r2-cockroachdb-access-key-id";
                };
              }
              {
                importer = "vault-file";
                arguments = {
                  path = self.lib.rumor.shared;
                  file = "cloudflare-r2-cockroachdb-secret-access-key";
                };
              }
            ];
            rumor.specification.generations = [
              {
                generator = "key";
                arguments = {
                  name = "cockroach-backup-pass";
                };
              }
              {
                generator = "moustache";
                arguments = {
                  name = "cockroach-backup-init";
                  renew = true;
                  variables = {
                    COCKROACH_BACKUP_PASS = "cockroach-backup-pass";

                    CLOUDFLARE_R2_COCKROACHDB_ENDPOINT = "cloudflare-r2-cockroachdb-endpoint";
                    CLOUDFLARE_R2_COCKROACHDB_ACCESS_KEY_ID = "cloudflare-r2-cockroachdb-access-key-id";
                    CLOUDFLARE_R2_COCKROACHDB_SECRET_ACCESS_KEY = "cloudflare-r2-cockroachdb-secret-access-key";
                  };
                  template =
                    let
                      backupConnectionStringTemplate =
                        "s3://cockroachdb/v1"
                        + "?AWS_REGION=auto"
                        + "&AWS_ENDPOINT={{CLOUDFLARE_R2_COCKROACHDB_ENDPOINT}}"
                        + "&AWS_ACCESS_KEY_ID={{CLOUDFLARE_R2_COCKROACHDB_ACCESS_KEY_ID}}"
                        + "&AWS_SECRET_ACCESS_KEY={{CLOUDFLARE_R2_COCKROACHDB_SECRET_ACCESS_KEY}}";
                    in
                    ''
                      create user if not exists backup password '{{COCKROACH_BACKUP_PASS}}';

                      grant system backup, externalioimplicitaccess to backup;

                      set role backup;

                      create schedule if not exists cluster_daily
                      for backup into '${backupConnectionStringTemplate}'
                      recurring '@daily' full backup always
                      with schedule options first_run = now;

                      reset role;
                    '';
                };
              }
            ];
            rumor.specification.exports = [
              {
                exporter = "vault-file";
                arguments = {
                  path = self.lib.rumor.shared;
                  file = "cockroach-backup-pass";
                };
              }
            ];
          };
    };
}
