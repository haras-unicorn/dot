{ lib, ... }:

# TODO: couple options

with lib;
{
  options.dot.editor = {
    pkg = mkOption {
      type = with types; str;
      default = "vim";
      example = "helix";
    };
    bin = mkOption {
      type = with types; str;
      default = "vim";
      example = "hx";
    };
    module = mkOption {
      type = with types; str;
      default = "vim";
      example = "helix";
    };
  };

  config = { };
}
