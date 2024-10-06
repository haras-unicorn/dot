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
        arg = "it.mijorus.smile";
      }];
    };
  };

  home.shared = {
    home.packages = with pkgs; [
      smile
    ];
  };
}
