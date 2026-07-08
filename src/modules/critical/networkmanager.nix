{
  machines.nixosModules.networkmanager =
    { lib, config, ... }:
    let
      hardware = config.dot.hardware;
    in
    lib.mkIf hardware.network {
      systemd.network.enable = false;
      systemd.network.wait-online.enable = false;

      networking.networkmanager.enable = true;

      programs.nm-applet.enable = lib.mkIf hardware.graphics true;
    };

  machines.homeModules.networkmanager =
    {
      pkgs,
      lib,
      osConfig,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;
    in
    lib.mkIf (hardware.network && hardware.graphics) {
      dot.desktop.network = lib.getExe' pkgs.networkmanagerapplet "nm-connection-editor";
    };
}
