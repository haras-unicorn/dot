{ lib, ... }:

# TODO: couple options

with lib;
{
  options.dot.visual = {
    visual.pkg = mkOption {
      type = with types; str;
      default = "vscode";
      example = "vscodium";
    };
    visual.bin = mkOption {
      type = with types; str;
      default = "code";
      example = "codium";
    };
    visual.module = mkOption {
      type = with types; str;
      default = "code";
      example = "code";
    };
  };

  config = { };
}
