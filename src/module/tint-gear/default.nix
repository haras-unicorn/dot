{ pkgs, tint-gear, system, config, lib, nix-colors, ... }:

let
  original = tint-gear.lib.colors {
    imagePath = config.dot.wallpaper;
  };

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
  options.dot = {
    wallpaper = lib.mkOption {
      type = lib.types.str;
      default = pkgs.nixos-artwork.wallpapers.nix-wallpaper-stripes-logo.src;
    };
    colors = lib.mkOption {
      default = { };
    };
  };

  config = {
    shared = {
      dot = {
        inherit colors;
      };
    };

    home.shared = {
      home.packages = [ tint-gear.packages."${system}".default ];

      xdg.configFile."tint-gear/colors.json".text = builtins.toJSON original;
    };
  };
}
