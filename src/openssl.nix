{ lib, config, ... }:

let
  hasNetwork = config.dot.hardware.network.enable;
in
{
  branch.nixosModule.nixosModule = {
    config = lib.mkIf hasNetwork {
      security.pki.certificates = [
        ''
          -----BEGIN CERTIFICATE-----
          MIIBWjCCAQCgAwIBAgIUSY5XVPR/Gnq4GZBBuZdH2veq940wCgYIKoZIzj0EAwIw
          DjEMMAoGA1UEAwwDRG90MB4XDTI1MDYwMTEwNTQxNloXDTM1MDUzMDEwNTQxNlow
          DjEMMAoGA1UEAwwDRG90MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEv9eBFfrh
          SriLoPmDiVB3MTYNSO3itMXfa5qlrSM6FZk+/CrYWLPik45hUO5vzaH0dJ5Yd6s1
          rKDe1I8bVrAxbaM8MDowDAYDVR0TBAUwAwEB/zALBgNVHQ8EBAMCAgQwHQYDVR0O
          BBYEFACBLdQ8lP/Fcsg7WW/70wNWd05DMAoGCCqGSM49BAMCA0gAMEUCIQDg5UDt
          OlAWt5qb7iUWthMnIAWZ3OX+IM5LV9siZeRS3AIgWsSTsxrjDcdqylz6G17zIaHe
          Vfy6Zv4nVCN+V1xQ1OY=
          -----END CERTIFICATE-----
        ''
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
