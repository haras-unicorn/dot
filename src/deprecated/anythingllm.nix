{ self, ... }:

{
  self.lib.deprecated.homeModules.anythingllm =
    {
      pkgs,
      lib,
      config,
      osConfig,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;

      dataDir = "${config.xdg.dataHome}/anythingllm";

      package = self.packages.${pkgs.stdenv.hostPlatform.system}.anythingllm;
    in
    lib.mkIf hardware.browser {
      home.packages = [
        package
      ];

      xdg.desktopEntries.anythingllm = {
        name = "AnythingLLM";
        exec = "${lib.getExe package} --user-data-dir=${dataDir}";
        terminal = false;
      };

      systemd.user.services.anythingllm = {
        Install.WantedBy = [ "graphical-session.target" ];
        Unit = {
          Description = "Anything LLM";
          After = [
            "tray.target"
            "graphical-session.target"
          ];
          PartOf = [ "graphical-session.target" ];
          Requires = [ "tray.target" ];
        };
        Service = {
          ExecStart = "${lib.getExe package} --user-data-dir=${dataDir}";
          Restart = "on-failure";
          WorkingDirectory = dataDir;
          Environment = "DISABLE_TELEMETRY=true";
          KillMode = "mixed";
          TimeoutStopSec = 15;
        };
      };
    };
}
