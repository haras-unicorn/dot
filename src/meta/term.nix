{ lib, ... }:

with lib;
{
  options.dot.term = {
    pkg = mkOption {
      type = with types; str;
      default = "kitty";
      example = "alacritty";
    };
    bin = mkOption {
      type = with types; str;
      default = "kitty";
      example = "alacritty";
    };
    module = mkOption {
      type = with types; str;
      default = "kitty";
      example = "alacritty";
    };
  };

  config = { };
}
