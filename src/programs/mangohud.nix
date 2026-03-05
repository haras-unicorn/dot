{
  flake.nixosModules.programs-mangohud =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      hasMonitor = config.dot.hardware.monitor.enable;
      hasMouse = config.dot.hardware.mouse.enable;
      hasKeyboard = config.dot.hardware.keyboard.enable;
    in
    {
      options = {
        dot.mangohud.package = lib.mkPackageOption pkgs "mangohud" { };
      };

      config = lib.mkIf (hasMonitor && hasMouse && hasKeyboard) {
        dot.mangohud.package = pkgs.mangohud;

        programs.steam.extraPackages = [
          config.dot.mangohud.package
        ];
      };
    };

  flake.homeModules.programs-mangohud =
    {
      pkgs,
      config,
      osConfig,
      lib,
      ...
    }:
    let
      hasMonitor = config.dot.hardware.monitor.enable;
      hasMouse = config.dot.hardware.mouse.enable;
      hasKeyboard = config.dot.hardware.keyboard.enable;
    in
    lib.mkIf (hasMonitor && hasMouse && hasKeyboard) {
      programs.mangohud.enable = true;
      programs.mangohud.package = osConfig.dot.mangohud.package;

      programs.lutris.extraPackages = [
        config.programs.mangohud.package
      ];
    };
}
