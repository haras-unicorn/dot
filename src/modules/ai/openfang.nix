{ inputs, ... }:

{
  machines.homeModules.openfang =
    {
      pkgs,
      lib,
      osConfig,
      ...
    }:
    let
      homeDir = "~/.openfang";
      systemdHome = builtins.replaceStrings [ "~" ] [ "%h" ] homeDir;

      listenPort = 4200;
      listenAddr = "127.0.0.1:${builtins.toString listenPort}";

      hardware = osConfig.dot.hardware;

      openfang = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.openfang;

      webUi = osConfig.dot.programs.chromium.launch {
        name = "openfang";
        address = "http://${listenAddr}";
      };

      configFormat = pkgs.formats.toml { };

      settings = {
        api_listen = listenAddr;
        log_level = "warn";
        mode = "stable";
        usage_footer = "off";

        default_model = {
          provider = "deepseek";
          model = "deepseek-v4-flash";
          api_key_env = "DEEPSEEK_API_KEY";
        };

        web.search_provider = "duck_duck_go";
      };

      configFile = configFormat.generate "config.toml" settings;
    in
    lib.mkMerge [
      {
        home.packages = [
          openfang
        ];

        home.file.".openfang/config.toml" = {
          force = true;
          source = configFile;
        };

        systemd.user.services.openfang = {
          Install = {
            WantedBy = [ "default.target" ];
          };
          Unit = {
            Description = "OpenFang Agent OS Daemon";
            Documentation = "https://www.openfang.sh/docs";
          };
          Service = {
            ExecStart = "${lib.getExe openfang} start";
            ExecStop = "${lib.getExe openfang} stop";
            Restart = "on-failure";
            RestartSec = 5;

            ProtectSystem = "strict";
            ProtectHome = "read-only";
            ReadWritePaths = [
              systemdHome
            ];

            PrivateTmp = true;
            PrivateDevices = true;
            PrivateIPC = true;

            RestrictAddressFamilies = "AF_INET AF_INET6";
            IPAddressDeny = "any";
            IPAddressAllow = "127.0.0.0/8 ::1";

            NoNewPrivileges = true;
            LockPersonality = true;

            SystemCallFilter = [
              "@system-service"
              "~@privileged"
              "~@resources"
            ];
            SystemCallArchitectures = "native";

            WorkingDirectory = systemdHome;
          };
        };
      }
      (lib.mkIf hardware.browser {
        home.packages = [
          webUi
        ];

        xdg.desktopEntries.openfang = {
          name = "OpenFang";
          exec = lib.getExe webUi;
          terminal = false;
        };
      })
    ];

}
