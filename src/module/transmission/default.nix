{
  # config, 
  pkgs
, ...
}:

# FIXME: the service thing always says the peer port is not open...

# NOTE: peer port is 51413
# NOTE: webui port is 9091

{
  system = {
    # services.transmission.enable = true;
    # services.transmission.openPeerPorts = true;
  };

  home.shared = {
    # xdg.desktopEntries = {
    #   transmission = {
    #     name = "Transmission";
    #     exec = "${config.dot.browser.package}/bin/${config.dot.browser.bin} --new-window localhost:9091";
    #     terminal = false;
    #   };
    # };

    home.packages = [
      pkgs.transmission_4-gtk
    ];
  };
}
