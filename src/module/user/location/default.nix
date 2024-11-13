{ config, ... }:

{
  system = {
    location.provider = "geoclue2";
    time.timeZone = "Europe/Zagreb";
    i18n.defaultLocale = "en_US.UTF-8";
    services.geoclue2.enable = true;
    programs.mepo.enable = config.dot.hardware.monitor.enable;
  };
}
