{ lib, ... }:

# TODO: font sizes?
# TODO: default, exmples and all

with lib;
let
  mkFontOption = type: {
    name = mkOption {
      type = with types; str;
    };
    pkg = mkOption {
      type = with types; str;
    };
  };
in
{
  options.dot.font = {
    nerd = mkFontOption "nerd";
    mono = mkFontOption "mono";
    slab = mkFontOption "slab";
    sans = mkFontOption "sans";
    serif = mkFontOption "serif";
    script = mkFontOption "script";
    emoji = mkFontOption "emoji";
    extra = mkOption {
      type = with types; listOf str;
      default = [ ];
    };
  };

  config = { };
}
