{ tint-gear, pkgs, system, config, lib, nix-colors, ... }:

let
  original = tint-gear.lib.colors {
    inherit pkgs;
    imagePath = config.dot.wallpaper;
  };

  toHexaColor = x: a: "${x}${builtins.toString a}";

  toAhexColor = x: a: "#${builtins.toString a}${builtins.substring 1 (-1) x}";

  toHyprColor = x: "0xff${builtins.substring 1 (-1) x}";

  toHyprAColor = x: a: "0x${a}${builtins.substring 1 (-1) x}";

  toVividColor = x: lib.strings.toUpper (builtins.substring 1 (-1) x);

  toRgbColor = x:
    let
      hex = builtins.substring 1 (-1) x;
      colors = nix-colors.lib.conversions.hexToRGB hex;
      r = builtins.toString (builtins.elemAt colors 0);
      g = builtins.toString (builtins.elemAt colors 1);
      b = builtins.toString (builtins.elemAt colors 2);
    in
    "rgb(${r}, ${g}, ${b})";

  toRgbaColor = x: a:
    let
      hex = builtins.substring 1 (-1) x;
      colors = nix-colors.lib.conversions.hexToRGB hex;
      r = builtins.toString (builtins.elemAt colors 0);
      g = builtins.toString (builtins.elemAt colors 1);
      b = builtins.toString (builtins.elemAt colors 2);
    in
    "rgba(${r}, ${g}, ${b}, ${builtins.toString a})";

  toMakoColor = x: x;

  toMakoAColor = x: a: "${toMakoColor x}${a}";

  toGtkColor = x: lib.strings.toUpper (builtins.substring 1 (-1) x);

  transformColors = colors:
    lib.attrsets.mapAttrsRecursive
      (
        (k: v:
          if builtins.isString v
          then {
            hex = v;
            hexa = toHexaColor v;
            ahex = toAhexColor v;
            hypr = toHyprColor v;
            hypra = toHyprAColor v;
            vivid = toVividColor v;
            rgb = toRgbColor v;
            rgba = toRgbaColor v;
            mako = toMakoColor v;
            makoa = toMakoAColor v;
            gtk = toGtkColor v;
          }
          else v)
      )
      original;

  colors = transformColors original;
in
{
  options = {
    colors = lib.mkOption {
      default = { };
    };
  };

  config = {
    inherit colors;
  };

  system = {
    stylix.enable = true;
    stylix.image = config.dot.wallpaper;
  };

  home = {
    home.packages = [ tint-gear.packages."${system}".default ];

    xdg.configFile."tint-gear/colors.json".text = builtins.toJSON original;

    stylix.enable = true;
    stylix.image = config.dot.wallpaper;
  };
}
