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
      default = transformColors (builtins.fromJSON ''{
        "isLightTheme": false,
        "colors": [
          "#3f4e55",
          "#a25d70",
          "#21291c",
          "#745963",
          "#33212c",
          "#516c8c",
          "#768c81"
        ],
        "bootstrap": {
          "primary": "#e79caf",
          "secondary": "#97a8b0",
          "accent": "#a9c0b5",
          "background": "#13261d",
          "backgroundAlternate": "#3c0019",
          "selection": "#040f15",
          "text": "#af98a5",
          "textAlternate": "#97a191",
          "danger": "#fe8d6c",
          "warning": "#b3f068",
          "info": "#4ee4fe"
        },
        "terminal": {
          "black": "#13261d",
          "white": "#af98a5",
          "brightBlack": "#3c0019",
          "brightWhite": "#97a191",
          "red": "#fe8d6c",
          "green": "#46f292",
          "blue": "#a295fe",
          "yellow": "#b3f068",
          "magenta": "#fe87f6",
          "cyan": "#4ee4fe",
          "brightRed": "#fe8d6c",
          "brightGreen": "#46f292",
          "brightBlue": "#a295fe",
          "brightYellow": "#b3f068",
          "brightMagenta": "#fe87f6",
          "brightCyan": "#4ee4fe"
        }
      }'');
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
