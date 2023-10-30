{ lib, ... }:

# TODO: couple options

with lib;
{
  options.dot.browser = {
    browser.pkg = mkOption {
      type = with types; str;
      default = "firefox";
      example = "vivaldi";
    };
    browser.bin = mkOption {
      type = with types; str;
      default = "firefox";
      example = "vivaldi";
    };
    browser.module = mkOption {
      type = with types; str;
      default = "firefox";
      example = "vivaldi";
    };
  };

  config = { };
}
