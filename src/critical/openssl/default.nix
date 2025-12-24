{ lib, config, ... }:

let
  hasNetwork = config.dot.hardware.network.enable;
in
{
  nixosModule = {
    config = lib.mkIf hasNetwork {
      security.pki.certificateFiles = [
        ./ca.crt
      ];

      sops.secrets."openssl-ca-public" = {
        owner = "root";
        group = "root";
        mode = "0644";
      };

      rumor.sops.keys = [
        "openssl-ca-public"
      ];

      rumor.specification.imports = [
        {
          importer = "vault-file";
          arguments = {
            path = "kv/dot/shared";
            file = "openssl-ca-private";
            allow_fail = true;
          };
        }
        {
          importer = "vault-file";
          arguments = {
            path = "kv/dot/shared";
            file = "openssl-ca-public";
            allow_fail = true;
          };
        }
        {
          importer = "vault-file";
          arguments = {
            path = "kv/dot/shared";
            file = "openssl-ca-serial";
            allow_fail = true;
          };
        }
      ];

      rumor.specification.generations = lib.mkBefore [
        {
          generator = "tls-root";
          arguments = {
            common_name = "Dot";
            organization = "Dot";

            config = "openssl-ca-config";
            private = "openssl-ca-private";
            public = "openssl-ca-public";
          };
        }
      ];

      rumor.specification.exports = [
        {
          exporter = "vault-file";
          arguments = {
            path = "kv/dot/shared";
            file = "openssl-ca-private";
          };
        }
        {
          exporter = "vault-file";
          arguments = {
            path = "kv/dot/shared";
            file = "openssl-ca-public";
          };
        }
        {
          exporter = "vault-file";
          arguments = {
            path = "kv/dot/shared";
            file = "openssl-ca-serial";
          };
        }
      ];
    };
  };
}
