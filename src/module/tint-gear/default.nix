{ tint-gear, system, config, ... }:

{
  shared = {
    dot = {
      colors = tint-gear.lib.colors {
        imagePath = config.dot.wallpaper;
      };
    };
  };

  home.shared = {
    home.packages = [ tint-gear.packages."${system}".default ];
  };
}
