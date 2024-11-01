{ pkgs, config, ... }:

{
  shared = {
    dot = {
      desktopEnvironment.keybinds = [
        {
          mods = [ ];
          key = "Print";
          command = "${pkgs.flameshot}/bin/flameshot gui -p '${config.xdg.userDirs.pictures}/screenshots'";
        }
      ];
    };
  };

  home = {
    services.flameshot.enable = true;
  };
}
