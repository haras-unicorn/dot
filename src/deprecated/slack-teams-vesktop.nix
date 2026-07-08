{
  self.lib.deprecated.nixosModules.slack-teams-vesktop =
    { lib, config, ... }:
    let
      hardware = config.dot.hardware;
    in
    lib.mkIf hardware.browser {
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

  self.lib.deprecated.homeModules.slack-teams-vesktop =
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

      slack = osConfig.dot.programs.chromium.wrap pkgs.slack;
      teams = osConfig.dot.programs.chromium.wrap pkgs.teams-for-linux;
      vesktop = osConfig.dot.programs.chromium.wrap pkgs.vesktop;

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
    in
    lib.mkIf hardware.browser {
      dot.desktop.windowrules = [
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
        teams
        vesktop
        slack
      ];

      xdg.configFile."teams-for-linux/config.json".text = builtins.toJSON {
        closeAppOnCross = true;
        trayIconEnabled = false;
      };
      xdg.configFile."teams-for-linux/window-state.json".text = builtins.toJSON windowState;
    };
}
