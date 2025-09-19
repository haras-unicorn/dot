{
  config,
  lib,
  pkgs,
  ...
}:

{
  branch.nixosModule.nixosModule = {
    # NOTE: https://github.com/NixOS/nixpkgs/issues/329522
    services.avahi.enable = true;
    services.geoclue2.enable = true;

    location.provider = "geoclue2";
    i18n.defaultLocale = "en_US.UTF-8";
    services.automatic-timezoned.enable = true;

    # NOTE: https://github.com/NixOS/nixpkgs/issues/293212#issuecomment-2319051915
    sops.secrets."geoclue-googleapi" = {
      path = "/etc/geoclue/conf.d/provider.conf";
      owner = "geoclue";
      group = "geoclue";
      mode = "0400";
    };

    rumor.sops = [ "geoclue-googleapi" ];
    rumor.specification.imports = [
      {
        importer = "vault-file";
        arguments = {
          path = "kv/dot/shared";
          file = "geoclue-googleapi";
        };
      }
    ];
  };

  branch.homeManagerModule.homeManagerModule = {
    home.packages = lib.mkIf config.dot.hardware.monitor.enable [
      pkgs.gnome-maps
    ];
  };
}
