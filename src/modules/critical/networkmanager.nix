{
  self.nixosModules.networkmanager.value =
    { lib, config, ... }:
    let
      hardware = config.dot.hardware;
    in
    lib.mkIf hardware.network {
      systemd.network.enable = false;
      systemd.network.wait-online.enable = false;

      networking.networkmanager.enable = true;
      networking.networkmanager.wifi.powersave = false;

      stolon.keep.directories = [ "/etc/NetworkManager/system-connections" ];

      programs.nm-applet.enable = lib.mkIf hardware.graphics true;
    };

  self.homeModules.networkmanager.value =
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
