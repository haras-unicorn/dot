{ pkgs, ... }:

{
  shared = {
    dot = {
      desktopEnvironment.keybinds = [
        {
          mods = [ "super" ];
          key = "e";
          command = "${pkgs.smile}/bin/smile";
        }
      ];

      desktopEnvironment.windowrules = [{
        rule = "float";
        selector = "class";
        xselector = "wm_class";
        arg = "it.mijorus.smile";
        xarg = "smile";
      }];
    };
  };

  home = {
    home.packages = with pkgs; [
      smile
    ];
  };
}
