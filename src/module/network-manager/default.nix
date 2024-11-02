{ ... }:

{
  shared.dot = {
    desktopEnvironment.windowrules = [{
      rule = "float";
      selector = "class";
      xselector = "wm_class";
      arg = "nm-connection-editor";
      xarg = "nm-connection-editor";
    }];
  };

  system = {
    networking.nftables.enable = true;
    networking.firewall.enable = true;
    networking.networkmanager.enable = true;
    networking.nameservers = [ "1.1.1.1" "1.0.0.1" ];
    networking.networkmanager.dns = "none";
  };

  home = {
    services.network-manager-applet.enable = true;
  };
}
