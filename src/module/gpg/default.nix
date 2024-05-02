{ pkgs, config, lib, ... }:

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
      default = "pinentry-curses";
      example = "pinentry-qt";
    };
    flavor = mkOption {
      type = with types; str;
      default = "tty";
      example = "qt";
    };
  };

  config = {
    home.shared = {
      home.packages = [
        pkgs."${config.dot.gpg.pkg}"
      ];

      programs.gpg.enable = true;
      services.gpg-agent.enable = true;
      services.gpg-agent.pinentryFlavor = "${config.dot.gpg.flavor}";
    };
  };
}
