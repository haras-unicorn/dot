let
  common =
    { lib, config, ... }:
    {
      options.dot = {
        hardware = {
          rpi = {
            "4".enable = lib.mkOption {
              type = lib.types.bool;
              description = ''
                Whether the host is a Raspbery Pi 4.
              '';
            };
          };

          threads = lib.mkOption {
            type = lib.types.ints.unsigned;
            description = ''
              Logical threads available on the host.
            '';
          };

          temp = lib.mkOption {
            type = lib.types.str;
            description = ''
              CPU temperature input file path.
            '';
          };

          memory = lib.mkOption {
            type = lib.types.ints.unsigned;
            description = ''
              Host memory in bytes.
            '';
          };

          disk = lib.mkOption {
            type = lib.types.ints.unsigned;
            description = ''
              Host root disk space in bytes.
            '';
          };

          battery.enable = lib.mkOption {
            type = lib.types.bool;
            description = ''
              Whether the host has a battery.
            '';
          };

          network = {
            enable = lib.mkOption {
              type = lib.types.bool;
              description = ''
                Whether the host has network access.
              '';
            };

            interface = lib.mkOption {
              type = lib.types.str;
              description = ''
                The main host network interface.
              '';
            };
          };

          graphics = {
            enable = lib.mkOption {
              type = lib.types.bool;
              description = ''
                Whether the host has a graphics device.
              '';
            };

            driver = lib.mkOption {
              type = lib.types.nullOr (
                lib.types.enum [
                  "nvidia"
                  "amdgpu"
                  "intel"
                ]
              );
              description = ''
                Driver of the main host graphics device.
              '';
            };

            version = lib.mkOption {
              type = lib.types.str;
              description = ''
                Main host graphics device driver version.
              '';
            };

            open = lib.mkOption {
              type = lib.types.bool;
              description = ''
                Whether the main host graphics device driver is open source.
              '';
            };

            busId = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              description = ''
                Bus ID of the main host graphics device.
              '';
            };

            wayland = lib.mkOption {
              type = lib.types.bool;
              description = ''
                Whether the main host graphics device supports Wayland.
              '';
            };

            integrated = {
              enable = lib.mkOption {
                type = lib.types.bool;
                description = ''
                  Whether the host CPU contains an integrated graphics device.
                '';
              };

              driver = lib.mkOption {
                type = lib.types.nullOr (
                  lib.types.enum [
                    "nvidia"
                    "amdgpu"
                    "intel"
                  ]
                );
                description = ''
                  The integrated graphics device driver.
                '';
              };

              busId = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                description = ''
                  The integrated graphics device driver.
                '';
              };
            };
          };

          sound.enable = lib.mkOption {
            type = lib.types.bool;
            description = ''
              Whether the host has a sound device.
            '';
          };

          monitor = {
            enable = lib.mkOption {
              type = lib.types.bool;
              description = ''
                Whether the host has a connected monitor.
              '';
            };

            main = lib.mkOption {
              type = lib.types.str;
              description = ''
                Main monitor ID.
              '';
            };

            width = lib.mkOption {
              type = lib.types.ints.unsigned;
              description = ''
                Main monitor width.
              '';
            };

            height = lib.mkOption {
              type = lib.types.ints.unsigned;
              description = ''
                Main monitor height.
              '';
            };

            dpi = lib.mkOption {
              type = lib.types.float;
              description = ''
                Main monitor DPI.
              '';
            };
          };

          keyboard.enable = lib.mkOption {
            type = lib.types.bool;
            description = ''
              Whether the host has a connected keyboard.
            '';
          };

          mouse.enable = lib.mkOption {
            type = lib.types.bool;
            description = ''
              Whether the host has a connected mouse.
            '';
          };

          bluetooth.enable = lib.mkOption {
            type = lib.types.bool;
            description = ''
              Whether the host is capable of bluetooth.
            '';
          };

          logitech.enable = lib.mkOption {
            type = lib.types.bool;
            description = ''
              Whether the host has a connected Logitech receiver.
            '';
          };
        };
      };
    };
in
{
  flake.nixosModules.capabilities-hardware = {
    imports = [ common ];
  };

  flake.homeModules.capabilities-hardware = {
    imports = [ common ];
  };
}
