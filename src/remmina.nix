{
  pkgs,
  config,
  lib,
  ...
}:

let
  hasMonitor = config.dot.hardware.monitor.enable;
in
{
  branch.homeManagerModule.homeManagerModule = lib.mkIf hasMonitor {
    home.packages = [
      pkgs.remmina
    ];
  };
}
