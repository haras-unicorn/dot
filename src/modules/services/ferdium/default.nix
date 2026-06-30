# FIXME: ferdium screen sharing and WebRTC
# NOTE: ferdium outlook - Self Hosted at https://outlook.office.com/mail/
{
  machines.nixosModules.ollama-openwebui =
    { lib, config, ... }:
    let
      hardware = config.dot.hardware;
    in
    lib.mkIf hardware.interface {
      dot.nixpkgs.allowUnfreePredicates = [
        (
          package:
          let
            name = lib.getName package;
          in
          name == "slack"
        )
      ];
    };

  machines.homeModules.ferdium =
    {
      config,
      osConfig,
      lib,
      pkgs,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;
      monitorWidth = hardware.width;
      monitorHeight = hardware.height;

      ferdium = osConfig.dot.programs.chromium.wrap pkgs.ferdium "ferdium";
      slack = osConfig.dot.programs.chromium.wrap pkgs.slack "slack";
      teams = osConfig.dot.programs.chromium.wrap pkgs.teams-for-linux "teams-for-linux";
      vesktop = osConfig.dot.programs.chromium.wrap pkgs.vesktop "vesktop";

      windowState = {
        width = monitorWidth * 3 / 4;
        height = monitorHeight * 3 / 4;
        x = monitorWidth / 4;
        y = monitorHeight / 4;
        displayBounds = {
          x = 0;
          y = 0;
          width = monitorWidth;
          height = monitorHeight;
        };
        isMaximized = true;
        isFullScreen = false;
      };

      settings = (builtins.fromJSON (builtins.readFile ./ferdium.json)) // {
        darkMode = config.stylix.polarity == "dark";
        accentColor = config.lib.stylix.colors.withHashtag.magenta;
        progressbarAccentColor = config.lib.stylix.colors.withHashtag.cyan;
      };

      mkFerdiumInstanceConfig =
        instanceName:
        let
          dataDir = "${config.xdg.dataHome}/ferdium/${instanceName}";
          prefix = "ferdium/${instanceName}";
        in
        {
          systemd.user.services."ferdium@${instanceName}" = {
            Unit = {
              Description = "Ferdium (${instanceName})";
              After = [ "graphical-session.target" ];
              Requires = [ "graphical-session.target" ];
            };
            Service = {
              ExecStartPre = [
                "${pkgs.coreutils}/bin/mkdir -p ${dataDir}/config"
              ];
              ExecStart = "${ferdium}/bin/ferdium --user-data-dir=${dataDir}";
              Restart = "on-failure";
              WorkingDirectory = dataDir;
            };
            Install.WantedBy = [ "graphical-session.target" ];
          };

          xdg.dataFile."${prefix}/config/settings.json".text = builtins.toJSON settings;

          xdg.dataFile."${prefix}/config/window-state.json".text = builtins.toJSON windowState;
          xdg.dataFile."${prefix}/window-state.json".text = builtins.toJSON windowState;
        };
    in
    lib.mkIf hardware.interface (
      lib.mkMerge [
        {
          dot.desktop.windowrules = [
            {
              rule = "float";
              selector = "class";
              arg = "ferdium";
            }
            {
              rule = "float";
              selector = "class";
              arg = "teams-for-linux";
            }
            {
              rule = "float";
              selector = "class";
              arg = "vesktop";
            }
          ];

          home.packages = [
            ferdium
            teams
            vesktop
            slack
          ];

          xdg.configFile."teams-for-linux/config.json".text = builtins.toJSON {
            closeAppOnCross = true;
            trayIconEnabled = false;
          };
          xdg.configFile."teams-for-linux/window-state.json".text = builtins.toJSON windowState;
        }
        (mkFerdiumInstanceConfig "personal")
        # (mkFerdiumInstanceConfig "work")
      ]
    );
}
