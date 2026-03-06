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
        virtualisation.memorySize = 8192; # in MiB
        virtualisation.cores = 4;
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

  # Generate test certificates for cockroachdb using cockroach cert command
  libAttrs.test.mkCockroachdbCerts =
    pkgs:
    { nodes, clients }:
    pkgs.runCommand "cockroachdb-test-certs"
      {
        nativeBuildInputs = [ pkgs.cockroachdb ];
      }
      ''
        mkdir -p $out

        # Create CA
        cockroach cert create-ca \
          --certs-dir=$out \
          --ca-key=$out/ca.key

        # Create node certificates for all nodes in the cluster
        ${builtins.concatStringsSep "\n" (
          builtins.map (
            { ip, name, ... }:
            ''
              cockroach cert create-node \
                ${name} \
                ${ip} \
                127.0.0.1 \
                localhost \
                --certs-dir=$out \
                --ca-key=$out/ca.key
              mv $out/node.crt $out/${name}.crt
              mv $out/node.key $out/${name}.key
            ''
          ) nodes
        )}

        # Create client certificate for root
        cockroach cert create-client root \
          --certs-dir=$out \
          --ca-key=$out/ca.key

        # Create additional client certificates
        ${builtins.concatStringsSep "\n" (
          builtins.map (
            { name, ... }:
            ''
              cockroach cert create-client ${name} \
                --certs-dir=$out \
                --ca-key=$out/ca.key
            ''
          ) clients
        )}

        # Set permissions
        chmod 644 $out/*.crt
        chmod 400 $out/*.key
      '';

  # Common cockroachdb node configuration for tests
  libAttrs.test.commonCockroachdbModule =
    let
      flakeConfig = config.flake;
    in
    { lib, config, ... }:
    let
      certsPackage = config.dot.test.cockroachdb.certs;
      certsPath = config.services.cockroachdb.certsDir;
      hostName = config.dot.host.name;
      initScript = config.dot.test.cockroachdb.init;
      cockroachdbUser = config.services.cockroachdb.user;
      cockroachdbGroup = config.services.cockroachdb.group;
    in
    {
      imports = [
        flakeConfig.nixosModules.critical-cockroachdb-nixpkgs
        flakeConfig.nixosModules.critical-cockroachdb
        flakeConfig.nixosModules.critical-consul
        flakeConfig.nixosModules.rumor
        flakeConfig.lib.test.mockNebulaChronydTargetsModule
        flakeConfig.lib.test.commonDotOptionsModule
        flakeConfig.lib.test.sopsSecretsModule
      ];

      options = {
        dot.test.cockroachdb.certs = lib.mkOption {
          type = lib.types.package;
          description = "Package of generated cockroachdb certificates the test";
        };
        dot.test.cockroachdb.init = lib.mkOption {
          type = lib.types.str;
          description = "Init script for cockroachdb";
        };
      };

      config = {
        system.activationScripts.cockroachdb-certs = {
          text = ''
            mkdir -p ${certsPath}
            cp ${certsPackage}/ca.crt ${certsPath}/
            cp ${certsPackage}/client.root.crt ${certsPath}/
            cp ${certsPackage}/client.root.key ${certsPath}/
            cp ${certsPackage}/${hostName}.crt ${certsPath}/node.crt
            cp ${certsPackage}/${hostName}.key ${certsPath}/node.key
            chown -R cockroachdb:cockroachdb ${certsPath}
            chmod 644 ${certsPath}/*.crt
            chmod 600 ${certsPath}/*.key
          '';
          deps = [
            "users"
            "groups"
          ];
        };

        environment.etc."cockroachdb/init.sql".text = initScript;

        sops.secrets = {
          "cockroach-ca-public" = {
            path = "${certsPath}/ca.crt";
            owner = cockroachdbUser;
            group = cockroachdbGroup;
            mode = "0644";
          };
          "cockroach-public" = {
            path = "${certsPath}/${hostName}.crt";
            owner = cockroachdbUser;
            group = cockroachdbGroup;
            mode = "0644";
          };
          "cockroach-private" = {
            path = "${certsPath}/${hostName}.key";
            owner = cockroachdbUser;
            group = cockroachdbGroup;
            mode = "0400";
          };
          "cockroach-root-public" = {
            path = "${certsPath}/client.root.crt";
            owner = cockroachdbUser;
            group = cockroachdbGroup;
            mode = "0644";
          };
          "cockroach-root-private" = {
            path = "${certsPath}/client.root.key";
            owner = cockroachdbUser;
            group = cockroachdbGroup;
            mode = "0400";
          };
          "cockroach-init" = {
            path = "/etc/cockroachdb/init.sql";
            owner = cockroachdbUser;
            group = cockroachdbGroup;
            mode = "0400";
          };
        };
      };
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
