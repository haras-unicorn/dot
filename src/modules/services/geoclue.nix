{
  machines.nixosModules.geoclue =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      location.provider = "geoclue2";
      i18n.defaultLocale = "en_US.UTF-8";

      services.geoclue2 = {
        enable = true;
        enableStatic = true;

        staticLatitude = config.dot.location.latitude;
        staticLongitude = config.dot.location.longitude;
        staticAltitude = config.dot.location.altitude;
        staticAccuracy = config.dot.location.accuracy;
      };
    };
}
