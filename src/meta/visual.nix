{ lib, ... }:

with lib;
{
  options.dot.visual = {
    pkg = mkOption {
      type = with types; str;
      default = "vscode";
      example = "vscodium";
    };
    bin = mkOption {
      type = with types; str;
      default = "code";
      example = "codium";
    };
    module = mkOption {
      type = with types; str;
      default = "code";
      example = "code";
    };
  };

  config = { };
}
