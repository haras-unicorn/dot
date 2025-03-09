{ pkgs, lib, config, ... }:

# FIXME: networkmanager-fortisslvpn
# TODO: openfortivpn as a service

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
    networking.nameservers = [ "1.1.1.1" "1.0.0.1" ];

    # NOTE: https://github.com/NixOS/nixpkgs/issues/231038
    environment.etc."ppp/options".text = ''
      ipcp-accept-remote
    '';

    environment.systemPackages = [
      pkgs.ppp
      pkgs.openfortivpn
      pkgs.networkmanager-fortisslvpn
    ];
  };

  branch.homeManagerModule.homeManagerModule = lib.mkIf (hasNetwork && hasMonitor) {
    dot.desktopEnvironment.windowrules = lib.mkIf hasKeyboard [{
      rule = "float";
      selector = "class";
      xselector = "wm_class";
      arg = "nm-connection-editor";
      xarg = "nm-connection-editor";
    }];

    services.network-manager-applet.enable = true;
  };
}
