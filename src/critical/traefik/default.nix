{
  flake.homeModules.critical-traefik =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      hasNetwork = config.dot.hardware.network.enable;
      hasMonitor = config.dot.hardware.monitor.enable;
    in
    lib.mkIf hasNetwork {
      home.packages = [
        pkgs.traefik
      ];

      xdg.desktopEntries = lib.mkIf hasMonitor {
        traefik = {
          name = "Traefik Dashboard";
          exec =
            "${config.dot.browser.package}/bin/${config.dot.browser.bin}"
            + " --new-window traefik.${config.dot.domains.service}";
          terminal = false;
        };
      };
    };

  flake.nixosModules.critical-traefik =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      hasNetwork = config.dot.hardware.network.enable;
      httpsPort = 443;
      # NOTE: not on "localhost" because resolved has "127.0.0.53:53"
      consulEndpoint = "${config.dot.host.ip}:8500";
    in
    {
      options.dot = {
        traefik.enable = lib.mkEnableOption "Traefik";
      };

      config = lib.mkIf (hasNetwork && config.dot.traefik.enable) {
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
            middlewares = {
              traefik-root-redirect.redirectregex = {
                regex = "^/$";
                replacement = "/dashboard/";
                permanent = true;
              };
              traefik-dashboard-slash.redirectregex = {
                regex = "^/dashboard$";
                replacement = "/dashboard/";
                permanent = true;
              };
            };

            routers = {
              dashboard = {
                rule =
                  "Host(`traefik.${config.dot.domains.service}`)"
                  + " && (PathPrefix(`/api`) || PathPrefix(`/dashboard`) || Path(`/`))";
                entryPoints = [ "websecure" ];
                service = "api@internal";
                middlewares = [
                  "traefik-root-redirect"
                  "traefik-dashboard-slash"
                ];
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
              defaultRule = "Host(`{{ normalize .Name }}.${config.dot.domains.service}`)";
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

        dot.services = [
          {
            name = "traefik";
            port = httpsPort;
            health = "tcp://";
          }
        ];

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

        rumor.sops.keys = [
          "traefik-private"
          "traefik-public"
        ];

        rumor.specification.generations = [
          {
            generator = "tls-leaf";
            arguments = {
              common_name = "dot";
              organization = "Dot";
              sans = [
                "*.${config.dot.domains.service}"
                "localhost"
                "${config.dot.host.ip}"
                "127.0.0.1"
              ];
              config = "traefik-cert-config";
              request_config = "traefik-cert-request-config";
              private = "traefik-private";
              request = "traefik-cert-request";
              ca_private = "openssl-ca-private";
              ca_public = "openssl-ca-public";
              serial = "openssl-ca-serial";
              public = "traefik-public";
              renew = true;
            };
          }
        ];
      };
    };
}
