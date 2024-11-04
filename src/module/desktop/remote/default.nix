{ pkgs, config, lib, ... }:

let
  hasMonitor = config.dot.hardware.monitor.enable;
in
{
  home = lib.mkIf hasMonitor {
    shared = {
      home.packages = [
        pkgs.remmina
      ];
    };
  };
}
