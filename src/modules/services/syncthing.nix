let
  port = 8384;
  address = "127.0.0.1:${builtins.toString port}";
in

{
  machines.nixosModules.syncthing =
    {
      lib,
      config,
      flake,
      ...
    }:
    let
      hardware = config.dot.hardware;
    in
    lib.mkIf hardware.network {
      networking.firewall.allowedTCPPorts = [
        port
      ];
    };

  machines.homeModules.syncthing =
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
    lib.mkIf hardware.network {
      services.syncthing.enable = true;
      services.syncthing.guiAddress = address;
      services.syncthing.tray.enable = lib.mkIf hardware.graphics true;

      xdg.desktopEntries = lib.mkIf hardware.browser {
        syncthing = {
          name = "Syncthing";
          exec = lib.getExe (osConfig.dot.programs.chromium.launch "syncthing" address true);
          terminal = false;
        };
      };
    };
}
