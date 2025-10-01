{
  pkgs,
  lib,
  config,
  ...
}:

# FIXME: networkmanager-fortisslvpn
# TODO: openfortivpn as a service

let
  hasNetwork = config.dot.hardware.network.enable;
  hasMonitor = config.dot.hardware.monitor.enable;
  hasKeyboard = config.dot.hardware.keyboard.enable;
  nameservers = [
    # Cloudflare
    "1.1.1.1"
    "1.0.0.1"
    # Google
    "8.8.8.8"
    "8.8.4.4"
  ];
in
{
  branch.nixosModule.nixosModule = lib.mkIf hasNetwork {
    networking.nftables.enable = true;
    networking.firewall.enable = true;

    networking.networkmanager.enable = true;
    networking.networkmanager.dns = "systemd-resolved";
    systemd.network.wait-online.enable = false;

    services.resolved.enable = true;
    services.resolved.fallbackDns = nameservers;

    # NOTE: https://github.com/NixOS/nixpkgs/issues/231038
    environment.etc."ppp/options".text = ''
      ipcp-accept-remote
    '';

    environment.systemPackages = [
      pkgs.ppp
      pkgs.openfortivpn
      pkgs.networkmanager-fortisslvpn
    ];

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
