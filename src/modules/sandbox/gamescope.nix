{
  machines.nixosModules.gamescope =
    { config, lib, ... }:
    let
      hardware = config.dot.hardware;
    in
    lib.mkIf hardware.gaming {
      programs.gamescope.enable = true;
      programs.gamescope.capSysNice = true;

      programs.steam.extraPackages = [
        config.programs.gamescope.package
      ];
    };

  machines.homeModules.gamescope =
    {
      osConfig,
      lib,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;
    in
    lib.mkIf hardware.gaming {
      programs.lutris.extraPackages = [
        osConfig.programs.gamescope.package
      ];
    };
}
