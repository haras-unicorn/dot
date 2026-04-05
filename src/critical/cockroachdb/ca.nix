{ self, ... }:

{
  flake.nixosModules.critical-cockroachdb-ca =
    {
      lib,
      config,
      pkgs,
      utils,
      ...
    }:
    let
      hasNetwork = config.dot.hardware.network.enable;

      certs = "/var/lib/cockroachdb/.certs";
    in
    lib.mkIf hasNetwork {
      sops.secrets."cockroach-ca-public" = {
        path = "${certs}/ca.crt";
        owner = config.services.cockroachdb.user;
        group = config.services.cockroachdb.group;
        mode = "0644";
      };

      cryl.sops.keys = [
        "cockroach-ca-public"
      ];
      cryl.specification.imports = [
        {
          importer = "vault-file";
          arguments = {
            path = self.lib.vault.shared;
            file = "cockroach-ca-private";
            allow_fail = true;
          };
        }
        {
          importer = "vault-file";
          arguments = {
            path = self.lib.vault.shared;
            file = "cockroach-ca-public";
            allow_fail = true;
          };
        }
      ];
      cryl.specification.generations = lib.mkBefore [
        {
          generator = "cockroach-ca";
          arguments = {
            private = "cockroach-ca-private";
            public = "cockroach-ca-public";
          };
        }
      ];
      cryl.specification.exports = [
        {
          exporter = "vault-file";
          arguments = {
            path = self.lib.vault.shared;
            file = "cockroach-ca-private";
          };
        }
        {
          exporter = "vault-file";
          arguments = {
            path = self.lib.vault.shared;
            file = "cockroach-ca-public";
          };
        }
      ];
    };
}
