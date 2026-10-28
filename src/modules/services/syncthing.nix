let
  port = 8384;
  address = "127.0.0.1:${builtins.toString port}";
in
{
  self.nixosModules.syncthing.value =
    {
      lib,
      config,
      flake,
      ...
    }:
    let
      hardware = config.dot.hardware;
    in
    lib.mkIf (hardware.network && hardware.browser) {
      networking.firewall.allowedTCPPorts = [
        port
      ];
    };

  self.homeModules.syncthing.value =
    {
      lib,
      config,
      osConfig,
      flake,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;
    in
    lib.mkIf (hardware.network && hardware.browser) {
      services.syncthing.enable = true;
      services.syncthing.guiAddress = address;
      services.syncthing.tray.enable = lib.mkIf hardware.graphics true;
    };
}
