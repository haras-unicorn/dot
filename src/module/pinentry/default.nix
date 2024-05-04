{ pkgs, config, lib, ... }:

let
  cfg = config.dot.pinentry;
in
{
  options.dot.pinentry = {
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.pinentry-curses;
      example = pkgs.pinentry-qt;
    };
    bin = lib.mkOption {
      type = lib.types.str;
      default = "pinentry-curses";
      example = "pinentry-qt";
    };
  };

  config = {
    home.shared = {
      home.packages = [ cfg.package ];

      services.gpg-agent.pinentryPackage = cfg.package;
    };
  };
}
