{ lib, ... }:

with lib;
{
  options.dot.gpg = {
    pkg = mkOption {
      type = with types; str;
      default = "pinentry";
      example = "pinentry-gtk2";
    };
    bin = mkOption {
      type = with types; str;
      default = "pinentry-tty";
      example = "pinentry-gtk-2";
    };
    flavor = mkOption {
      type = with types; str;
      default = "tty";
      example = "gtk2";
    };
  };

  config = { };
}
