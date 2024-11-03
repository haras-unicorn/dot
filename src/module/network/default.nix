{ pkgs, config, ... }:

# FIXME: networkmanager-fortisslvpn
# TODO: openfortivpn as a service
# NOTE: https://github.com/qdm12/ddns-updater/blob/master/docs/duckdns.md -> /var/lib/ddns-updater/config.json

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

    # NOTE: https://github.com/NixOS/nixpkgs/issues/231038
    environment.etc."ppp/options".text = ''
      ipcp-accept-remote
    '';

    environment.systemPackages = with pkgs; [
      ppp
      openfortivpn
      networkmanager-fortisslvpn
    ];

    services.openssh.enable = true;
    services.openssh.allowSFTP = true;
    services.openssh.settings.PermitRootLogin = "no";
    services.openssh.settings.PasswordAuthentication = true;
    services.openssh.settings.KbdInteractiveAuthentication = false;

    services.ddns-updater.enable = true;
    services.ddns-updater.environment = {
      CONFIG_FILEPATH = "/etc/ddns-updater.json";
    };
  };

  home = {
    services.network-manager-applet.enable = true;
    xdg.desktopEntries = {
      ddns-updater = {
        name = "DDNS Updater";
        exec = "${config.dot.browser.package}/bin/${config.dot.browser.bin} --new-window localhost:8000";
        terminal = false;
      };
    };
  };
}
