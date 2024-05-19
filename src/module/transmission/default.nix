{ config, ... }:

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
