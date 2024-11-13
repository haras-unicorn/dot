{ config, ... }:

{
  system = {
    # NOTE: https://github.com/NixOS/nixpkgs/issues/329522
    services.avahi.enable = true;
    services.geoclue2.enable = true;
    # NOTE: https://github.com/NixOS/nixpkgs/issues/293212#issuecomment-2319051915
    services.geoclue2.geoProviderUrl = "https://beacondb.net/v1/geolocate?key=geoclue";


    location.provider = "geoclue2";
    i18n.defaultLocale = "en_US.UTF-8";
    services.automatic-timezoned.enable = true;
    programs.mepo.enable = config.dot.hardware.monitor.enable;
  };
}
