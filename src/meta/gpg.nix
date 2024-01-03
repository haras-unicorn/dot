{ lib, ... }:

with lib;
{
  options.dot.gpg = {
    pkg = mkOption {
      type = with types; str;
      default = "pinentry";
      example = "pinentry-qt";
    };
    bin = mkOption {
      type = with types; str;
      default = "pinentry-tty";
      example = "pinentry-qt";
    };
    flavor = mkOption {
      type = with types; str;
      default = "tty";
      example = "qt";
    };
  };

  config = { };
}
