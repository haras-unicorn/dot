{ pkgs, config, lib, ... }:

let
  hasMonitor = config.dot.hardware.monitor.enable;

  package = lib.mkMerge [
    (lib.mkIf hasMonitor pkgs.pinentry-qt)
    (lib.mkIf (!hasMonitor) pkgs.pinentry-curser)
  ];
in
{
  home = {
    home.packages = [ package ];
    services.gpg-agent.pinentryPackage = package;
  };
}
