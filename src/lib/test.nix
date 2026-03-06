{ config, ... }:

{
  libAttrs.test.mkTest =
    pkgs:
    {
      name,
      nodes,
      script,
    }:
    pkgs.testers.runNixOSTest {
      inherit name nodes;
      testScript = script;
      sshBackdoor.enable = true;
      defaults = {
        virtualisation.memorySize = 4096; # in MiB
        virtualisation.cores = 2;
        # Workaround for nixpkgs gzip/install-info issue
        documentation.info.enable = false;
      };
    };

  libAttrs.test.commonDotOptionsModule =
    { pkgs, lib, ... }:
    {
      options = {
        dot.hardware.network.enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
        };
        dot.hardware.monitor.enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
        };
        dot.host.name = lib.mkOption {
          type = lib.types.str;
          default = "testhost";
        };
        dot.host.user = lib.mkOption {
          type = lib.types.str;
          default = "testuser";
        };
        dot.host.ip = lib.mkOption {
          type = lib.types.str;
          default = "192.168.1.10";
        };
        dot.host.hosts = lib.mkOption {
          type = lib.types.listOf lib.types.attrs;
          default = [ ];
        };
        dot.browser.package = lib.mkOption {
          type = lib.types.package;
          default = pkgs.firefox;
        };
        dot.browser.bin = lib.mkOption {
          type = lib.types.str;
          default = "firefox";
        };
      };
    };

  libAttrs.test.sopsSecretsModule =
    { lib, ... }:
    {
      options = {
        sops.secrets = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.submodule {
              options = {
                path = lib.mkOption { type = lib.types.str; };
                owner = lib.mkOption {
                  type = lib.types.str;
                  default = "root";
                };
                group = lib.mkOption {
                  type = lib.types.str;
                  default = "root";
                };
                mode = lib.mkOption {
                  type = lib.types.str;
                  default = "0400";
                };
                key = lib.mkOption {
                  type = lib.types.str;
                  default = "";
                };
              };
            }
          );
          default = { };
        };
      };
    };

  libAttrs.test.mockNebulaChronydTargetsModule =
    { lib, ... }:
    {
      systemd.targets.nebula-online = {
        description = lib.mkDefault "Mock nebula-online target";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
      };
      systemd.targets.chronyd-synced = {
        description = lib.mkDefault "Mock chronyd-synced target";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
      };
    };

  libAttrs.test.rumorOptionsModule =
    { lib, ... }:
    let
      rumorSpecificationSubmodule = lib.types.submodule {
        options = {
          imports = lib.mkOption {
            type = lib.types.listOf lib.types.raw;
            default = [ ];
          };
          generations = lib.mkOption {
            type = lib.types.listOf lib.types.raw;
            default = [ ];
          };
          exports = lib.mkOption {
            type = lib.types.listOf lib.types.raw;
            default = [ ];
          };
        };
      };
      rumorSopsSubmodule = lib.types.submodule {
        options = {
          keys = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
          };
          path = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
          };
        };
      };
    in
    {
      options = {
        rumor = lib.mkOption {
          type = lib.types.nullOr (
            lib.types.submodule {
              options = {
                specification = rumorSpecificationSubmodule;
                sops = rumorSopsSubmodule;
              };
            }
          );
          default = null;
        };
      };
    };

  libAttrs.test.mkDisabledServiceTest =
    pkgs:
    {
      name,
      module,
      serviceName,
      configPath,
    }:
    config.flake.lib.test.mkTest pkgs {
      inherit name;
      nodes.machine = {
        imports = [
          module
          config.flake.nixosModules.rumor
          config.flake.lib.test.commonDotOptionsModule
          config.flake.lib.test.sopsSecretsModule
        ];

        networking.hostName = "testhost";

        users.users.testuser = {
          isNormalUser = true;
          home = "/home/testuser";
          uid = 1000;
        };
        users.groups.testuser = {
          gid = 1000;
        };

        # The module's enable option defaults to false
      };
      script = ''
        start_all()

        # When service is disabled, service should not be enabled
        machine.fail("systemctl is-enabled ${serviceName}")

        # Verify no config directory is created
        machine.fail("test -d ${configPath}")
      '';
    };

  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];
  perSystem =
    { pkgs, ... }:
    {
      checks.test-test = config.flake.lib.test.mkTest pkgs {
        name = "Test test";
        nodes.test =
          { pkgs, ... }:
          {
            environment.systemPackages = [ pkgs.hello ];
          };
        script = ''
          start_all()
          test.succeed("hello")
        '';
      };
    };

  flake.tests = {
    test-test = {
      expr = true;
      expected = true;
    };
  };
}
