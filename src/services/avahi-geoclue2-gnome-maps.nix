{
  config,
  lib,
  pkgs,
  ...
}:

{
  nixosModule = {
    # NOTE: https://github.com/NixOS/nixpkgs/issues/329522
    services.avahi.enable = true;
    services.geoclue2.enable = true;
    services.geoclue2.enableStatic = true;
    # NOTE: disable the generated one from nixpkgs
    environment.etc.geolocation.enable = lib.mkForce false;

    location.provider = "geoclue2";
    i18n.defaultLocale = "en_US.UTF-8";
    services.automatic-timezoned.enable = true;

    # NOTE: https://github.com/NixOS/nixpkgs/issues/293212#issuecomment-2319051915
    # sops.secrets."geoclue-static-geolocation" = {
    #   path = "/etc/geolocation";
    #   owner = "geoclue";
    #   group = "geoclue";
    #   mode = "0440";
    # };

    rumor.sops = [ "geoclue-static-geolocation" ];
    rumor.specification.imports = [
      {
        importer = "vault-file";
        arguments = {
          path = "kv/dot/shared";
          file = "geoclue-static-geolocation";
        };
      }
    ];
  };

  homeManagerModule = {
    home.packages = lib.mkIf config.dot.hardware.monitor.enable [
      pkgs.gnome-maps
    ];
  };
}
