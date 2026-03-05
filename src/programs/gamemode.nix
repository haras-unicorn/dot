{
  flake.nixosModules.programs-gamemode =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      user = config.dot.host.user;

      hasMonitor = config.dot.hardware.monitor.enable;
      hasMouse = config.dot.hardware.mouse.enable;
      hasKeyboard = config.dot.hardware.keyboard.enable;
    in
    {
      options = {
        dot.gamemode.package = lib.mkPackageOption pkgs "gamemode" { };
      };

      config = lib.mkIf (hasKeyboard && hasMonitor && hasMouse) {
        dot.gamemode.package = pkgs.gamemode;

        programs.gamemode.enable = true;
        programs.gamemode.enableRenice = true;

        users.users.${user}.extraGroups = [
          "gamemode"
        ];

        programs.steam.extraPackages = [
          config.dot.gamemode.package
        ];
      };
    };

  flake.homeModules.programs-gamemode =
    {
      osConfig,
      config,
      lib,
      ...
    }:
    let
      hasMonitor = config.dot.hardware.monitor.enable;
      hasMouse = config.dot.hardware.mouse.enable;
      hasKeyboard = config.dot.hardware.keyboard.enable;
    in
    lib.mkIf (hasKeyboard && hasMonitor && hasMouse) {
      programs.lutris.extraPackages = [
        osConfig.dot.gamemode.package
      ];
    };
}
