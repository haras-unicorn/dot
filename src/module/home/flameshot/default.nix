{ pkgs, config, ... }:

{
  de.keybinds = [
    {
      mods = [ ];
      key = "Print";
      command = "${pkgs.flameshot}/bin/flameshot gui -p '${config.xdg.userDirs.pictures}/screenshots'";
    }
  ];

  services.flameshot.enable = true;
}
