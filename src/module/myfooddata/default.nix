{ config, ... }:

{
  home.shared = {
    xdg.desktopEntries = {
      syncthing = {
        name = "My Food Data";
        exec = "${config.dot.browser.package}/bin/${config.dot.browser.bin} --new-window https://myfooddata.com/";
        terminal = false;
      };
    };
  };
}

