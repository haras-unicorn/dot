{ lib, ... }:

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
    sans = mkFontOption "sans";
    serif = mkFontOption "serif";
    nerd = mkFontOption "nerd";
    emoji = mkFontOption "emoji";
  };

  config = { };
}
