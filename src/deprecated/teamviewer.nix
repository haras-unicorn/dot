{
  self.lib.deprecated.nixosModules.teamviewer =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    let
      hardware = config.dot.hardware;
    in
    lib.mkIf (hardware.browser && hardware.network) {
      services.teamviewer.enable = true;
      environment.systemPackages = with pkgs; [
        teamviewer
      ];
    };
}
