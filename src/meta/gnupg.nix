{ lib, ... }:

# TODO: couple options

with lib;
{
  options.dot.gnupg = {
    gnupg.pkg = mkOption {
      type = with types; str;
      default = "pinentry";
      example = "pinentry-gtk2";
    };
    gnupg.bin = mkOption {
      type = with types; str;
      default = "pinentry-tty";
      example = "pinentry-gtk-2";
    };
    gnupg.flavor = mkOption {
      type = with types; str;
      default = "tty";
      example = "gtk2";
    };
  };

  config = { };
}
