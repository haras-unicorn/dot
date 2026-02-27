{
  flake.nixosModules.services-swayosd =
    {
      pkgs,
      lib,
      config,
      ...
    }:

    let
      hasMonitor = config.dot.hardware.monitor.enable;
      hasWayland = config.dot.hardware.graphics.wayland;
    in
    lib.mkIf (hasMonitor && hasWayland) {
      environment.systemPackages = [ pkgs.swayosd ];
      services.udev.packages = [ pkgs.swayosd ];

      systemd.services.swayosd-libinput-backend = {
        description = "SwayOSD LibInput backend for listening to certain keys like CapsLock, ScrollLock, VolumeUp, etc.";
        documentation = [ "https://github.com/ErikReider/SwayOSD" ];
        wantedBy = [ "graphical.target" ];
        partOf = [ "graphical.target" ];
        after = [ "graphical.target" ];

        serviceConfig = {
          Type = "dbus";
          BusName = "org.erikreider.swayosd";
          ExecStart = "${pkgs.swayosd}/bin/swayosd-libinput-backend";
          Restart = "on-failure";
        };
      };
    };

  flake.homeModules.services-swayosd =
    {
      lib,
      config,
      ...
    }:
    let
      hasMonitor = config.dot.hardware.monitor.enable;
      hasWayland = config.dot.hardware.graphics.wayland;
    in
    lib.mkIf (hasMonitor && hasWayland) {
      services.swayosd.enable = true;
    };
}
