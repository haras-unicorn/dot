{
  machines.nixosModules.mangohud =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      hardware = config.dot.hardware;
    in
    lib.mkIf hardware.gaming {
      dot.programs.mangohud.package = pkgs.mangohud;

      programs.steam.extraPackages = [
        config.dot.programs.mangohud.package
      ];
    };

  machines.homeModules.mangohud =
    {
      pkgs,
      config,
      osConfig,
      lib,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;
    in
    lib.mkIf hardware.gaming {
      programs.mangohud.enable = true;
      programs.mangohud.package = osConfig.dot.programs.mangohud.package;

      programs.lutris.extraPackages = [
        osConfig.dot.programs.mangohud.package
      ];
    };
}
