{ pkgs, config, ... }:

let
  hasMonitor = builtins.hasAttr "monitor" config.facter.report.hardware;
  package = if hasMonitor then pkgs.pinentry-qt else pkgs.pinentry-curses;
in
{
  home = {
    home.packages = [ package ];
    services.gpg-agent.pinentryPackage = package;
  };
}
