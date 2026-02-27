{
  flake.nixosModules.services-teamviewer =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    let
      hasMonitor = config.dot.hardware.monitor.enable;
      hasNetwork = config.dot.hardware.network.enable;
    in
    lib.mkIf (hasMonitor && hasNetwork) {
      services.teamviewer.enable = true;
      environment.systemPackages = with pkgs; [
        teamviewer
      ];
    };
}
