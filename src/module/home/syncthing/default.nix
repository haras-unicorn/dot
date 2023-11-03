{ pkgs, config, ... }:

{
  services.syncthing.enable = true;
  services.syncthing.tray.enable = true;

  xdg.desktopEntries = {
    syncthing = {
      name = "Syncthing";
      exec = "${pkgs."${config.dot.browser.pkg}"}/bin/${config.dot.browser.bin} localhost:8384";
      terminal = false;
    };
  };
}
