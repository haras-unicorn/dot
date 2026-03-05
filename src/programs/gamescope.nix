{
  flake.nixosModules.programs-gamescope =
    { config, lib, ... }:
    let
      hasMonitor = config.dot.hardware.monitor.enable;
      hasMouse = config.dot.hardware.mouse.enable;
      hasKeyboard = config.dot.hardware.keyboard.enable;
    in
    lib.mkIf (hasKeyboard && hasMonitor && hasMouse) {
      programs.gamescope.enable = true;
      programs.gamescope.capSysNice = true;

      programs.steam.extraPackages = [
        config.programs.gamescope.package
      ];
    };

  flake.homeModules.programs-gamescope =
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
        osConfig.programs.gamescope.package
      ];
    };
}
