{
  self.nixosModules.flatpak-warehouse.value =
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

      stolon.keep.directories = [ "/var/lib/flatpak" ];
    };

  self.homeModules.flatpak-warehouse.value =
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
