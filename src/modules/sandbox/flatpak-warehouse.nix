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
    lib.mkIf hardware.browser {
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
    lib.mkIf hardware.browser {
      home.packages = [
        pkgs.warehouse
      ];
    };
}
