{ lib, config, host, ... }:

let
  hasNetwork = config.dot.hardware.network.enable;
  hasMonitor = config.dot.hardware.monitor.enable;
  isCoordinator = config.dot.ddns.coordinator;
in
{
  options = {
    ddns.coordinator = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  integrate.nixosModule.nixosModule = lib.mkIf (hasNetwork && isCoordinator) {
    services.ddns-updater.enable = true;
    services.ddns-updater.environment = {
      CONFIG_FILEPATH = "/etc/ddns-updater/config.json";
      PERIOD = "5m";
    };
    users.users.ddns-updater = {
      group = "ddns-updater";
      description = "DDNS updater service user";
      isSystemUser = true;
    };
    users.groups.ddns-updater = { };
    systemd.services.ddns-updater = {
      serviceConfig = {
        DynamicUser = lib.mkForce false;
        User = "ddns-updater";
        Group = "ddns-updater";
      };
    };
    sops.secrets."${host}.ddns" = {
      path = "/etc/ddns-updater/config.json";
      owner = "ddns-updater";
      group = "ddns-updater";
      mode = "0400";
    };
  };

  integrate.homeManagerModule.homeManagerModule = lib.mkIf (hasNetwork && hasMonitor && isCoordinator) {
    xdg.desktopEntries = {
      ddns-updater = {
        name = "DDNS Updater";
        exec = "${config.dot.browser.package}/bin/${config.dot.browser.bin} --new-window localhost:8000";
        terminal = false;
      };
    };
  };
}
