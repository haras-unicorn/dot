{ config, ... }:

{
  home.shared = {
    services.syncthing.enable = true;
    # TODO: fix tray is not available on boot
    # services.syncthing.tray.enable = true;

    xdg.desktopEntries = {
      syncthing = {
        name = "Syncthing";
        exec = "${config.dot.browser.package}/bin/${config.dot.browser.bin} --new-window localhost:8384";
        terminal = false;
      };
    };
  };
}
