{ lib, ... }:

with lib;
{
  options.dot.shell = {
    pkg = mkOption {
      type = with types; str;
      default = "bash";
      example = "nushell";
    };
    bin = mkOption {
      type = with types; str;
      default = "bash";
      example = "nu";
    };
    module = mkOption {
      type = with types; str;
      default = "bash";
      example = "nushell";
    };
  };

  config = { };
}
