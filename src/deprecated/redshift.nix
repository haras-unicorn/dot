{
  self.lib.deprecated.nixosModules.redshift =
    {
      config,
      lib,
      ...
    }:
    let
      hardware = config.dot.hardware;
    in
    {
      config = lib.mkIf (hardware.graphics && !hardware.wayland) {
        services.avahi.enable = true; # NOTE: https://github.com/NixOS/nixpkgs/issues/329522
        services.geoclue2.enable = true;
      };
    };

  self.lib.deprecated.homeModules.redshift =
    {
      osConfig,
      lib,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;
    in
    {
      config = lib.mkIf (hardware.graphics && !hardware.wayland) {
        services.redshift.enable = true;
        services.redshift.provider = "geoclue2";
      };
    };
}
