{ config, ... }:

{
  home.shared = {
    xdg.desktopEntries = {
      myfooddata = {
        name = "My Food Data";
        exec = "${config.dot.browser.package}/bin/${config.dot.browser.bin} --new-window https://myfooddata.com/";
        terminal = false;
      };
    };
  };
}

