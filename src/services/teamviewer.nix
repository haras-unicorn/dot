{
  pkgs,
  config,
  lib,
  ...
}:

let
  hasMonitor = config.dot.hardware.monitor.enable;
  hasNetwork = config.dot.hardware.network.enable;
in
{
  nixosModule = lib.mkIf (hasMonitor && hasNetwork) {
    services.teamviewer.enable = true;
    environment.systemPackages = with pkgs; [
      teamviewer
    ];
  };
}
