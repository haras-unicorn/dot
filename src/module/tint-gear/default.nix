{ tint-gear, system, config, lib, nix-colors, ... }:

let
  original = tint-gear.lib.colors {
    imagePath = config.dot.wallpaper;
  };

  toHyprColor = x: "0xff${builtins.substring 1 (-1) x}";

  toVividColor = x: lib.strings.toUpper (builtins.substring 1 (-1) x);

  toRgbColor = x:
    let
      colors = nix-colors.lib.conversions.hexToRGB x;
      r = colors .0;
      g = colors .1;
      b = colors .2;
    in
    "rgb(${r}, ${g}, ${b})";

  toRgbaColor = x: a:
    let
      colors = nix-colors.lib.conversions.hexToRGB x;
      r = colors .0;
      g = colors .1;
      b = colors .2;
    in
    "rgba(${r}, ${g}, ${b}, ${a})";

  toMakoColor = x: lib.strings.toUpper (builtins.substring 1 (-1) x);

  toMakoAColor = x: a: "${toMakoColor x}${a}";

  colors = lib.attrsets.mapAttrsRecursive
    (
      (k: v:
        if builtins.isString v
        then {
          hex = v;
          hypr = toHyprColor v;
          vivid = toVividColor v;
          rgb = toRgbColor v;
          rgba = toRgbaColor v;
          mako = toMakoColor v;
          makoa = toMakoAColor v;
        }
        else v)
    )
    original;
in
{
  shared = {
    dot = {
      inherit colors;
    };
  };

  home.shared = {
    home.packages = [ tint-gear.packages."${system}".default ];

    xdg.configFile."tint-gear/colors.json".text = builtins.toJSON original;
  };
}
