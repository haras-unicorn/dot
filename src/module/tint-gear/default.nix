{ tint-gear, system, config, ... }:

let
  colors = tint-gear.lib.colors {
    imagePath = config.dot.wallpaper;
  };
in
{
  shared = {
    dot = {
      inherit colors;
    };
  };

  home.shared = {
    home.packages = [ tint-gear.packages."${system}".default ];

    xdg.configFile."tint-gear/colors.json".text = builtins.toJSON colors;
  };
}
