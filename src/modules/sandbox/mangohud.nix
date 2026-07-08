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
      dot.commands.mangohud = pkgs.mangohud;

      programs.steam.extraPackages = [
        config.dot.commands.mangohud
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
      programs.mangohud.package = osConfig.dot.commands.mangohud;

      programs.lutris.extraPackages = [
        osConfig.dot.commands.mangohud
      ];
    };
}
