{
  machines.nixosModules.flatpak-warehouse =
    {
      config,
      lib,
      ...
    }:
    let
      hardware = config.dot.hardware;
    in
    lib.mkIf hardware.interface {
      services.flatpak.enable = true;
    };

  machines.homeModules.flatpak-warehouse =
    {
      pkgs,
      lib,
      osConfig,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;
    in
    lib.mkIf hardware.interface {
      home.packages = [
        pkgs.warehouse
      ];
    };
}
