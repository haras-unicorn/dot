{ lib, ... }:

# TODO: this is ok for a start but i want better fonts

with lib;
let
  mkFontOption = type: name: pkg: {
    name = mkOption {
      type = with types; str;
      default = name;
      example = name;
    };
    pkg = mkOption {
      type = with types; str;
      default = pkg;
      example = pkg;
    };
  };
in
{
  options.dot.font = {
    nerd = mkFontOption "nerd" "JetBrainsMono Nerd Font" "JetBrainsMono";
    mono = mkFontOption "mono" "Roboto Mono" "roboto-mono";
    slab = mkFontOption "slab" "Roboto Slab" "roboto-slab";
    sans = mkFontOption "sans" "Roboto" "roboto";
    serif = mkFontOption "serif" "Roboto Serif" "roboto-serif";
    script = mkFontOption "script" "Eunomia" "dotcolon-fonts";
    emoji = mkFontOption "emoji" "Noto Color Emoji" "noto-fonts-emoji";
    extra = mkOption {
      type = with types; listOf str;
      default = [ ];

    };
    size = {
      small = mkOption {
        type = with types; int;
        default = 12;
        example = 12;
      };
      medium = mkOption {
        type = with types; int;
        default = 13;
        example = 13;
      };
      large = mkOption {
        type = with types; int;
        default = 16;
        example = 16;
      };
    };
  };

  config = { };
}
