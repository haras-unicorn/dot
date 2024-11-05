{ pkgs, config, lib, ... }:

let
  hasMonitor = config.dot.hardware.monitor.enable;
in
{
  home = lib.mkIf hasMonitor {
    home.packages = [
      pkgs.remmina
    ];
  };
}
