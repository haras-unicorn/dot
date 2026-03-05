{
  flake.homeModules.programs-lutris =
    {
      pkgs,
      config,
      lib,
      osConfig,
      ...
    }:
    let
      hasMonitor = config.dot.hardware.monitor.enable;
      hasMouse = config.dot.hardware.mouse.enable;
      hasKeyboard = config.dot.hardware.keyboard.enable;
    in
    lib.mkIf (hasMonitor && hasMouse && hasKeyboard) {
      programs.lutris.enable = true;
      programs.lutris.defaultWinePackage = pkgs.proton-ge-bin;
    };
}
