{ pkgs, lib, config, ... }:

let
  hasNetwork = config.dot.hardware.network.enable;
  hasMonitor = config.dot.hardware.monitor.enable;
  httpsPort = 443;
  # NOTE: not on "localhost" because resolved has "127.0.0.53:53"
  consulEndpoint = "${config.dot.host.ip}:8500";
  hosts = builtins.map
    (x: x.ip)
    (builtins.filter
      (x:
        if lib.hasAttrByPath [ "system" "dot" "traefik" "coordinator" ] x
        then x.system.dot.traefik.coordinator
        else false)
      config.dot.hosts);
  firstHost = builtins.head hosts;
  dashboardAddress = "https://${firstHost}";
in
{
  branch.homeManagerModule.homeManagerModule = lib.mkIf hasNetwork {
    home.packages = [
      pkgs.traefik
    ];

    xdg.desktopEntries = lib.mkIf hasMonitor {
      traefik = {
        name = "Traefik Dashboard";
        exec = "${config.dot.browser.package}/bin/${config.dot.browser.bin}"
          + " --new-window ${dashboardAddress}";
        terminal = false;
      };
    };
  };

  branch.nixosModule.nixosModule = {
    options.dot = {
      traefik.coordinator = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
    };

    config = lib.mkIf (hasNetwork && config.dot.traefik.coordinator) {
      services.traefik.enable = true;
      services.traefik.group = "traefik";

      services.traefik.dynamicConfigOptions = {
        tls = {
          certificates = [
            {
              certFile = config.sops.secrets."traefik-public".path;
              keyFile = config.sops.secrets."traefik-private".path;
              stores = [ "default" ];
            }
          ];
          stores = {
            default = {
              defaultCertificate = {
                certFile = config.sops.secrets."traefik-public".path;
                keyFile = config.sops.secrets."traefik-private".path;
              };
            };
          };
        };

        http = {
          routers = {
            dashboard = {
              rule = "Host(`traefik.service.consul`)"
                + " && (PathPrefix(`/api`) || PathPrefix(`/dashboard`))";
              entryPoints = [ "websecure" ];
              service = "api@internal";
            };
          };
        };
      };

      services.traefik.staticConfigOptions = {
        api = {
          dashboard = true;
        };

        entryPoints = {
          websecure = {
            address = ":${builtins.toString httpsPort}";
            http.tls = { };
          };
        };

        providers = {
          consul = {
            rootKey = "dot";
            endpoints = [ consulEndpoint ];
            tls = {
              ca = config.sops.secrets."traefik-ca-public".path;
              cert = config.sops.secrets."traefik-public".path;
              key = config.sops.secrets."traefik-private".path;
              insecureSkipVerify = false;
            };
          };

          consulCatalog = {
            prefix = "dot";
            exposedByDefault = false;
            defaultRule = "Host(`{{ normalize .Name }}.service.consul`)";
            endpoint = {
              address = consulEndpoint;
              scheme = "https";
              tls = {
                ca = config.sops.secrets."traefik-ca-public".path;
                cert = config.sops.secrets."traefik-public".path;
                key = config.sops.secrets."traefik-private".path;
                insecureSkipVerify = false;
              };
            };
          };
        };
      };

      dot.consul.services = [{
        name = "traefik";
        port = httpsPort;
        address = config.dot.host.ip;
        check = {
          tcp = "${config.dot.host.ip}:${builtins.toString httpsPort}";
          interval = "30s";
          timeout = "10s";
        };
      }];

      networking.firewall.allowedTCPPorts = [
        httpsPort
      ];

      programs.rust-motd.settings = {
        service_status = {
          Traefik = "traefik";
        };
      };

      sops.secrets."traefik-ca-public" = {
        key = "openssl-ca-public";
        owner = config.systemd.services.traefik.serviceConfig.User;
        group = config.systemd.services.traefik.serviceConfig.User;
        mode = "0644";
      };
      sops.secrets."traefik-public" = {
        owner = config.systemd.services.traefik.serviceConfig.User;
        group = config.systemd.services.traefik.serviceConfig.User;
        mode = "0644";
      };
      sops.secrets."traefik-private" = {
        owner = config.systemd.services.traefik.serviceConfig.User;
        group = config.systemd.services.traefik.serviceConfig.User;
        mode = "0400";
      };

      rumor.sops = [
        "traefik-private"
        "traefik-public"
      ];

      rumor.specification.generations = [
        {
          generator = "text";
          arguments = {
            name = "traefik-cert-config";
            renew = true;
            text = ''
              [req]
              distinguished_name = req_distinguished_name
              prompt = no

              [req_distinguished_name]
              CN = Traefik
              O = Dot

              [ext]
              basicConstraints = CA:FALSE
              keyUsage = nonRepudiation,digitalSignature,keyEncipherment
              subjectAltName = @alt_names


              [alt_names]
              DNS.1 = *.service.consul
              DNS.2 = ${config.dot.host.name}.dot
              DNS.3 = localhost
              IP.1 = ${config.dot.host.ip}
              IP.2 = 127.0.0.1
            '';
          };
        }
        {
          generator = "openssl";
          arguments = {
            ca_private = "openssl-ca-private";
            ca_public = "openssl-ca-public";
            serial = "openssl-ca-serial";
            config = "traefik-cert-config";
            private = "traefik-private";
            public = "traefik-public";
            renew = true;
          };
        }
      ];
    };
  };
}
