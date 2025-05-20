{ config, lib, pkgs, ... }:

let
  hasNetwork = config.dot.hardware.network.enable;

  locationsSubmodule.options = {
    port = lib.mkOption {
      type = lib.types.port;
    };
  };
in
{
  branch.homeManagerModule.homeManagerModule = lib.mkIf hasNetwork {
    home.packages = [ pkgs.nginx pkgs.openssl ];
  };

  branch.nixosModule.nixosModule = {
    options.dot.nginx = {
      coordinator = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      locations = lib.mkOption {
        type = lib.types.attrsOf
          (lib.types.submodule locationsSubmodule);
        default = { };
      };
    };

    config = lib.mkMerge [
      (lib.mkIf hasNetwork {
        security.pki.certificates = [
          config.sops.secrets."nginx-ca-public".path
        ];

        sops.secrets."nginx-ca-public" = {
          owner = "root";
          group = "root";
          mode = "0644";
        };

        rumor.sops = [
          "nginx-ca-public"
        ];
        rumor.specification.imports = [
          {
            importer = "vault-file";
            arguments = {
              path = "kv/dot/shared";
              file = "nginx-ca-private";
              allow_fail = true;
            };
          }
          {
            importer = "vault-file";
            arguments = {
              path = "kv/dot/shared";
              file = "nginx-ca-public";
              allow_fail = true;
            };
          }
        ];
        rumor.specification.generations = [
          {
            generator = "text";
            arguments = {
              name = "nginx-ca-config";
              text = ''
                [ ca ]
                default_ca = ca_details

                [ ca_details ]
                policy = policy_lenient

                [ policy_lenient ]
                commonName = supplied

                [ req ]
                prompt = no
                distinguished_name = ca_dn

                [ ca_dn ]
                CN = dot

                [ v3_ca ]
                basicConstraints = critical,CA:true
                keyUsage = critical,keyCertSign
              '';
            };
          }
          {
            generator = "openssl-ca";
            arguments = {
              private = "nginx-ca-private";
              public = "nginx-ca-public";
              config = "nginx-ca-config";
            };
          }
        ];
        rumor.specification.exports = [
          {
            exporter = "vault-file";
            arguments = {
              path = "kv/dot/shared";
              file = "nginx-ca-private";
            };
          }
          {
            exporter = "vault-file";
            arguments = {
              path = "kv/dot/shared";
              file = "nginx-ca-public";
            };
          }
        ];
      })
      (lib.mkIf (hasNetwork && config.dot.nginx.coordinator) {
        services.nginx.enable = true;
        services.nginx.recommendedGzipSettings = true;
        services.nginx.recommendedOptimisation = true;
        services.nginx.recommendedProxySettings = true;
        services.nginx.recommendedTlsSettings = true;
        services.nginx.sslDhparam = config.sops.secrets."nginx-cert-dhparam".path;

        services.nginx.virtualHosts.${config.dot.host.ip} = {
          onlySSL = true;
          sslCertificate = config.sops.secrets."nginx-cert-public".path;
          sslCertificateKey = config.sops.secrets."nginx-cert-private".path;
          locations = builtins.mapAttrs
            (_: { port, ... }: {
              proxyPass = "http://localhost:${builtins.toString port}";
              proxyWebsockets = true;
            })
            config.dot.nginx.locations;
        };

        networking.firewall.allowedTCPPorts = [ 80 443 ];

        sops.secrets."nginx-cert-private" = {
          owner = config.services.nginx.user;
          group = config.services.nginx.group;
          mode = "0400";
        };
        sops.secrets."nginx-cert-public" = {
          owner = config.services.nginx.user;
          group = config.services.nginx.group;
          mode = "0644";
        };
        sops.secrets."nginx-cert-dhparam" = {
          owner = config.services.nginx.user;
          group = config.services.nginx.group;
          mode = "0400";
        };
        rumor.sops = [
          "nginx-cert-public"
          "nginx-cert-private"
          "nginx-cert-dhparam"
        ];
        rumor.specification.imports = [
          {
            importer = "vault-file";
            arguments = {
              path = "kv/dot/shared";
              file = "nginx-ca-serial";
              allow_fail = true;
            };
          }
        ];
        rumor.specification.generations = [
          {
            generator = "text";
            arguments = {
              name = "nginx-cert-config";
              text = ''
                [ req ]
                prompt = no
                distinguished_name = server_dn

                [ server_dn ]
                CN = ${config.dot.host.name}

                [ ext ]
                basicConstraints = critical,CA:FALSE
                keyUsage = critical,digitalSignature,keyEncipherment
                subjectAltName = @alt_names

                [ alt_names ]
                DNS.1 = ${config.dot.host.name}.dot
                IP.1 = ${config.dot.host.ip}
              '';
            };
          }
          {
            generator = "openssl";
            arguments = {
              renew = true;
              ca_public = "nginx-ca-public";
              ca_private = "nginx-ca-private";
              serial = "nginx-ca-serial";
              private = "nginx-cert-private";
              public = "nginx-cert-public";
              config = "nginx-cert-config";
            };
          }
          {
            generator = "openssl-dhparam";
            arguments = {
              name = "nginx-cert-dhparam";
            };
          }
        ];
        rumor.specification.exports = [
          {
            exporter = "vault-file";
            arguments = {
              path = "kv/dot/shared";
              file = "nginx-ca-serial";
            };
          }
        ];
      })
    ];
  };
}
