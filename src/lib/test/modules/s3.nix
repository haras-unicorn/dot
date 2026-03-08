{
  libAttrs.test.modules.s3 =
    {
      lib,
      config,
      ...
    }:
    let
      testConfig = config;

      getPort =
        address:
        lib.toInt (builtins.elemAt (builtins.filter builtins.isString (builtins.split ":" address)) 1);
    in
    {
      options.dot.test = {
        s3 = {
          enable = lib.mkEnableOption "S3 test server (MinIO)";
          accessKey = lib.mkOption {
            type = lib.types.str;
            default = "minioadmin";
            description = "MinIO access key (root user)";
          };
          secretKey = lib.mkOption {
            type = lib.types.str;
            default = "minioadmin";
            description = "MinIO secret key (root password)";
          };
          buckets = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "List of bucket names to create automatically";
          };
        };
      };

      config = lib.mkIf testConfig.dot.test.s3.enable {
        dot.test.external = builtins.listToAttrs (
          builtins.map (bucket: {
            name = "s3-${bucket}";
            value = {
              node = "s3";
              protocol = "s3";
              path = bucket;
              parameters = {
                AWS_REGION = "auto";
                AWS_ENDPOINT =
                  "http://${testConfig.nodes.s3.dot.host.ip}"
                  + ":${builtins.toString (getPort testConfig.nodes.s3.services.minio.listenAddress)}";
                AWS_ACCESS_KEY_ID = testConfig.dot.test.s3.accessKey;
                AWS_SECRET_ACCESS_KEY = testConfig.dot.test.s3.secretKey;
              };
            };
          }) testConfig.dot.test.s3.buckets
        );

        dot.test.commands.prefix = lib.mkBefore ''
          s3.wait_for_unit("dot-test-s3-initialized.target")
        '';

        nodes.s3 =
          { pkgs, lib, ... }:
          {
            services.minio = {
              enable = true;
              rootCredentialsFile = pkgs.writeText "minio-credentials" ''
                MINIO_ROOT_USER=${testConfig.dot.test.s3.accessKey}
                MINIO_ROOT_PASSWORD=${testConfig.dot.test.s3.secretKey}
              '';
            };

            networking.firewall.allowedTCPPorts = [
              (getPort config.services.minio.listenAddress)
              (getPort config.services.minio.consoleAddress)
            ];

            systemd.services.minio-bucket-init = lib.mkIf (testConfig.dot.test.s3.buckets != [ ]) {
              description = "Initialize MinIO buckets";
              after = [ "minio.service" ];
              requires = [ "minio.service" ];
              wantedBy = [ "multi-user.target" ];
              serviceConfig = {
                Type = "oneshot";
              };
              environment = {
                MC_HOST_local =
                  "http://${testConfig.dot.test.s3.accessKey}"
                  + ":${testConfig.dot.test.s3.secretKey}"
                  + "@localhost"
                  + ":${builtins.toString (getPort config.services.minio.listenAddress)}";
              };
              path = [ pkgs.minio-client ];
              script = ''
                for i in {1..30}; do
                  if mc ls local 2>/dev/null; then
                    break
                  fi
                  echo "Waiting for MinIO to be ready..."
                  sleep 1
                done

                ${lib.concatMapStrings (bucket: ''
                  echo "Creating bucket: ${bucket}"
                  mc mb --ignore-existing local/${bucket}
                '') testConfig.dot.test.s3.buckets}

                echo "Bucket initialization complete"
              '';
            };

            systemd.targets.dot-test-s3-initialized = {
              description = "Dot test S3 initialized";
              requires = lib.mkMerge [
                (lib.mkIf (testConfig.dot.test.s3.buckets != [ ]) [ "minio-bucket-init.service" ])
                (lib.mkIf (testConfig.dot.test.s3.buckets == [ ]) [ "minio.service" ])
              ];
              after = lib.mkMerge [
                (lib.mkIf (testConfig.dot.test.s3.buckets != [ ]) [ "minio-bucket-init.service" ])
                (lib.mkIf (testConfig.dot.test.s3.buckets == [ ]) [ "minio.service" ])
              ];
              wantedBy = [ "multi-user.target" ];
            };
          };
      };
    };
}
