{ pkgs, config, lib, ... }:

{
  options.dot.gpg = {
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.pinentry;
      example = pkgs.pinentry-qt;
    };
    bin = lib.mkOption {
      type = lib.types.str;
      default = "pinentry-curses";
      example = "pinentry-qt";
    };
    flavor = lib.mkOption {
      type = lib.types.str;
      default = "tty";
      example = "qt";
    };
  };

  config = {
    home.shared = {
      home.packages = [
        config.dot.gpg.package
      ];

      programs.gpg.enable = true;
      services.gpg-agent.enable = true;
      services.gpg-agent.pinentryFlavor = "${config.dot.gpg.flavor}";
    };
  };
}
