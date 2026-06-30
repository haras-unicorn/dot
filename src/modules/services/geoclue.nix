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

        # NOTE: Zagreb, Croatia
        staticLatitude = 45.815010;
        staticLongitude = 15.981919;
        staticAltitude = 125;
        staticAccuracy = 30000;
      };
    };
}
