{
  machines.nixosModules.gamescope =
    { config, lib, ... }:
    let
      hardware = config.dot.hardware;
    in
    lib.mkIf hardware.gaming {
      dot.commands.gamescope = config.programs.gamescope.package;

      programs.gamescope.enable = true;
      programs.gamescope.capSysNice = true;

      programs.steam.extraPackages = [
        config.dot.commands.gamescope
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
        osConfig.dot.commands.gamescope
      ];
    };
}
