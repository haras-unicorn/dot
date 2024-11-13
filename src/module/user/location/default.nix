{ config, ... }:

{
  system = {
    services.avahi.enable = true; # NOTE: https://github.com/NixOS/nixpkgs/issues/329522
    services.geoclue2.enable = true;

    location.provider = "geoclue2";
    i18n.defaultLocale = "en_US.UTF-8";
    services.automatic-timezoned.enable = true;
    programs.mepo.enable = config.dot.hardware.monitor.enable;
  };
}
