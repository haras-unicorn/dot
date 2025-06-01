{ lib, config, ... }:

let
  hasNetwork = config.dot.hardware.network.enable;
in
{
  branch.nixosModule.nixosModule = {
    config = lib.mkIf hasNetwork {
      security.pki.certificates = [
        config.sops.secrets."openssl-ca-public".path
      ];

      sops.secrets."openssl-ca-public" = {
        owner = "root";
        group = "root";
        mode = "0644";
      };

      rumor.sops = [
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
          generator = "text";
          arguments = {
            name = "openssl-ca-config";
            text = ''
              [req]
              distinguished_name = req_distinguished_name
              x509_extensions = v3_ca
              prompt = no

              [req_distinguished_name]
              CN = Dot

              [v3_ca]
              basicConstraints = CA:TRUE
              keyUsage = keyCertSign
            '';
          };
        }
        {
          generator = "openssl-ca";
          arguments = {
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
