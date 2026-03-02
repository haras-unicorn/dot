{ config, ... }:

{
  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];

  perSystem =
    { pkgs, ... }:
    {
      checks.test-critical-openssl = config.flake.lib.test.mkTest pkgs {
        name = "critical-openssl";
        nodes.machine = {
          imports = [
            config.flake.nixosModules.critical-openssl
            config.flake.nixosModules.rumor
          ];
          options = {
            dot.hardware.network.enable = pkgs.lib.mkOption {
              type = pkgs.lib.types.bool;
              default = true;
            };
            sops.secrets = pkgs.lib.mkOption {
              type = pkgs.lib.types.attrsOf (
                pkgs.lib.types.submodule {
                  options = {
                    path = pkgs.lib.mkOption { type = pkgs.lib.types.str; };
                    owner = pkgs.lib.mkOption {
                      type = pkgs.lib.types.str;
                      default = "root";
                    };
                    group = pkgs.lib.mkOption {
                      type = pkgs.lib.types.str;
                      default = "root";
                    };
                    mode = pkgs.lib.mkOption {
                      type = pkgs.lib.types.str;
                      default = "0400";
                    };
                  };
                }
              );
              default = { };
            };
          };
        };
        script = ''
          start_all()

          # Verify the system has SSL certificates directory
          machine.succeed("test -d /etc/ssl/certs")

          # Check that CA certificates are configured and directory is not empty
          machine.succeed("test -n \"$(ls -A /etc/ssl/certs/)\"")

          machine.log("OpenSSL module configuration verified successfully")
        '';
      };
    };
}
