{ config, lib, ... }:

{
  options.dot.location = {
    timeZone = lib.mkOption {
      type = lib.types.str;
      default = "Etc/UTC";
      example = "Etc/UTC";
    };
  };

  config = {
    system = {
      location.provider = "geoclue2";
      time.timeZone = "${config.dot.location.timeZone}";
      i18n.defaultLocale = "en_US.UTF-8";
    };
  };
}
