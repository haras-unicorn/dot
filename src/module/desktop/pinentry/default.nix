{ pkgs, config, ... }:

let
  package = if config.dot.hardware.monitor then pkgs.pinentry-qt else pkgs.pinentry-curses;
in
{
  home = {
    home.packages = [ package ];
    services.gpg-agent.pinentryPackage = package;
  };
}
