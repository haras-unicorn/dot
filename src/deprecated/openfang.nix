{ inputs, ... }:

{
  self.lib.deprecated.homeModules.openfang =
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

      toolchainBin = lib.makeBinPath [
        pkgs.python3
        pkgs.nodejs
        pkgs.rustc
        pkgs.cargo
        osConfig.dot.programs.chromium.package
      ];

      configFormat = pkgs.formats.toml { };

      settings = {
        include = [ "local.toml" ];

        api_listen = listenAddr;
        log_level = "warn";
        mode = "stable";
        usage_footer = "off";

        exec_policy.mode = "deny";
      };
    in
    lib.mkMerge [
      {
        home.packages = [
          openfang
        ];

        home.file.".openfang/config.toml".source = configFormat.generate "config.toml" settings;

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
            Environment = [ "PATH=${toolchainBin}" ];

            ProtectSystem = "strict";
            ProtectHome = true;
            BindPaths = [ systemdHome ];

            PrivateTmp = true;
            PrivateDevices = true;

            RestrictAddressFamilies = "AF_INET AF_INET6";

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
