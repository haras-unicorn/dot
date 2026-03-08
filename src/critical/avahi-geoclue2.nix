{ self, ... }:

{
  flake.nixosModules.critical-avahi-geoclue2 =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      hasNetwork = config.dot.hardware.network.enable;
    in
    lib.mkIf hasNetwork {
      # NOTE: https://github.com/NixOS/nixpkgs/issues/329522
      services.avahi.enable = true;
      services.geoclue2.enable = true;
      services.geoclue2.enableStatic = true;
      # NOTE: disable the generated one from nixpkgs
      environment.etc.geolocation.enable = lib.mkForce false;

      location.provider = "geoclue2";
      i18n.defaultLocale = "en_US.UTF-8";
      services.automatic-timezoned.enable = true;

      # NOTE: https://github.com/NixOS/nixpkgs/issues/293212#issuecomment-2319051915
      # sops.secrets."geoclue-static-geolocation" = {
      #   path = "/etc/geolocation";
      #   owner = "geoclue";
      #   group = "geoclue";
      #   mode = "0440";
      # };

      cryl.sops.keys = [ "geoclue-static-geolocation" ];
      cryl.specification.imports = [
        {
          importer = "vault-file";
          arguments = {
            path = self.lib.cryl.shared;
            file = "geoclue-static-geolocation";
          };
        }
      ];
    };

  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];
  perSystem =
    { pkgs, ... }:
    {
      checks.test-critical-avahi-geoclue2-disabled = self.lib.test.mkTest pkgs {
        name = "critical-avahi-geoclue2-disabled";
        dot.test.disabledService.enable = true;
        dot.test.disabledService.module =
          { lib, ... }:
          {
            imports = [
              self.nixosModules.critical-avahi-geoclue2
            ];

            dot.hardware.network.enable = lib.mkForce false;
          };
        dot.test.disabledService.name = "geoclue2";
        dot.test.disabledService.config = "/etc/geolocation";
      };

      checks.test-critical-avahi-geoclue2-enabled = self.lib.test.mkTest pkgs {
        name = "critical-avahi-geoclue2-enabled";

        dot.test.cryl.shared.specification.generations = [
          {
            generator = "text";
            arguments = {
              name = "geoclue-static-geolocation";
              text = "1";
            };
          }
        ];

        nodes.machine = {
          imports = [
            self.nixosModules.critical-avahi-geoclue2
          ];
        };

        dot.test.commands.suffix = ''
          machine.wait_for_unit("avahi-daemon.service")
          machine.wait_for_unit("geoclue.service")
        '';
      };
    };
}
