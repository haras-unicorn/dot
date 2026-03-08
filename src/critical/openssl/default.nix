{ self, ... }:

{
  flake.nixosModules.critical-openssl =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    {
      options.dot = {
        openssl = {
          enable = (lib.mkEnableOption "OpenSSL") // {
            default = true;
          };
        };
      };

      config = lib.mkIf config.dot.openssl.enable {
        security.pki.certificatePaths = [ config.sops.secrets."openssl-ca-public".path ];
        security.pki.buildOnActivation = true;

        sops.secrets."openssl-ca-public" = {
          owner = "root";
          group = "root";
          mode = "0644";
        };

        cryl.sops.keys = [
          "openssl-ca-public"
        ];

        cryl.specification.imports = [
          {
            importer = "vault-file";
            arguments = {
              path = self.lib.cryl.shared;
              file = "openssl-ca-private";
              allow_fail = true;
            };
          }
          {
            importer = "vault-file";
            arguments = {
              path = self.lib.cryl.shared;
              file = "openssl-ca-public";
              allow_fail = true;
            };
          }
          {
            importer = "vault-file";
            arguments = {
              path = self.lib.cryl.shared;
              file = "openssl-ca-serial";
              allow_fail = true;
            };
          }
        ];

        cryl.specification.generations = lib.mkBefore [
          {
            generator = "tls-root";
            arguments = {
              common_name = "dot";
              organization = "Dot";
              config = "openssl-ca-config";
              private = "openssl-ca-private";
              public = "openssl-ca-public";
            };
          }
        ];
        cryl.specification.exports = [
          {
            exporter = "vault-file";
            arguments = {
              path = self.lib.cryl.shared;
              file = "openssl-ca-private";
            };
          }
          {
            exporter = "vault-file";
            arguments = {
              path = self.lib.cryl.shared;
              file = "openssl-ca-public";
            };
          }
        ]
        ++ (lib.optional
          (builtins.any (
            { generator, arguments }:
            (
              generator == "tls-leaf"
              || generator == "tls-rsa-leaf"
              || generator == "tls-intermediary"
              || generator == "tls-rsa-intermediary"
            )
            && arguments.ca_public == "openssl-ca-public"
            && arguments.ca_private == "openssl-ca-private"
            && arguments.serial == "openssl-ca-serial"
          ) config.cryl.specification.generations)
          {
            exporter = "vault-file";
            arguments = {
              path = self.lib.cryl.shared;
              file = "openssl-ca-serial";
            };
          }
        );
      };
    };
}
