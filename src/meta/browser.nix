{ lib, ... }:

with lib;
{
  options.dot.browser = {
    pkg = mkOption {
      type = with types; str;
      default = "firefox";
      example = "vivaldi";
    };
    bin = mkOption {
      type = with types; str;
      default = "firefox";
      example = "vivaldi";
    };
    module = mkOption {
      type = with types; str;
      default = "firefox";
      example = "vivaldi";
    };
  };

  config = { };
}
