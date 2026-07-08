{
  self.lib.deprecated.nixosModules.swayosd =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      hardware = config.dot.hardware;
    in
    lib.mkIf (hardware.visual && hardware.wayland) {
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
          ExecStart = lib.getExe' pkgs.swayosd "swayosd-libinput-backend";
          Restart = "on-failure";
        };
      };
    };

  self.lib.deprecated.homeModules.swayosd =
    {
      lib,
      osConfig,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;
    in
    lib.mkIf (hardware.visual && hardware.wayland) {
      services.swayosd.enable = true;
    };
}
