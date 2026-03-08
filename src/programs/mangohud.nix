let
  common =
    { lib, pkgs, ... }:
    {
      options.dot = {
        mangohud.package = lib.mkPackageOption pkgs "mangohud" { };
      };
    };
in
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
      imports = [ common ];

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
    {
      imports = [ common ];

      config = lib.mkMerge [
        { dot.mangohud.package = lib.mkDefault osConfig.dot.mangohud.package; }
        (lib.mkIf (hasMonitor && hasMouse && hasKeyboard) {
          programs.mangohud.enable = true;
          programs.mangohud.package = config.dot.mangohud.package;

          programs.lutris.extraPackages = [
            config.programs.mangohud.package
          ];
        })
      ];
    };
}
