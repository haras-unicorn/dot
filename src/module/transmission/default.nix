{ config, ... }:

# NOTE: peer port is 51413
# NOTE: webui port is 9091

{
  system = {
    services.transmission.enable = true;
    services.transmission.openPeerPorts = true;
  };

  home.shared = {
    xdg.desktopEntries = {
      transmission = {
        name = "Transmission";
        exec = "${config.dot.browser.package}/bin/${config.dot.browser.bin} localhost:9091";
        terminal = false;
      };
    };
  };
}
