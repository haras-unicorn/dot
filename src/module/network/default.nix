{ pkgs, lib, config, ... }:

# FIXME: networkmanager-fortisslvpn
# TODO: openfortivpn as a service

let
  hasNetwork = config.dot.hardware.network.enable;
  hasMonitor = config.dot.hardware.monitor.enable;
  hasKeyboard = config.dot.hardware.keyboard.enable;
in
{
  config = lib.mkIf (hasNetwork && hasMonitor && hasKeyboard) {
    desktopEnvironment.windowrules = [{
      rule = "float";
      selector = "class";
      xselector = "wm_class";
      arg = "nm-connection-editor";
      xarg = "nm-connection-editor";
    }];
  };

  system = lib.mkIf hasNetwork {
    networking.nftables.enable = true;
    networking.firewall.enable = true;
    networking.networkmanager.enable = true;
    networking.nameservers = [ "1.1.1.1" "1.0.0.1" ];
    networking.networkmanager.dns = "none";

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

  home = lib.mkIf (hasNetwork && hasMonitor) {
    services.network-manager-applet.enable = true;
  };
}
