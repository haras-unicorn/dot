{
  pkgs,
  lib,
  config,
  ...
}:

let
  hasNetwork = config.dot.hardware.network.enable;
  hasMonitor = config.dot.hardware.monitor.enable;
  hasKeyboard = config.dot.hardware.keyboard.enable;
in
{
  branch.nixosModule.nixosModule = lib.mkIf hasNetwork {
    networking.nftables.enable = true;
    networking.firewall.enable = true;

    networking.networkmanager.enable = true;
    systemd.network.wait-online.enable = false;

    programs.rust-motd.settings = {
      service_status = {
        Network = "systemd-networkd";
      };
    };
  };

  branch.homeManagerModule.homeManagerModule = lib.mkIf (hasNetwork && hasMonitor) {
    dot.desktopEnvironment.windowrules = lib.mkIf hasKeyboard [
      {
        rule = "float";
        selector = "class";
        arg = "nm-connection-editor";
      }
    ];

    services.network-manager-applet.enable = true;

    dot.desktopEnvironment.network = "${pkgs.networkmanagerapplet}/bin/nm-connection-editor";
  };
}
