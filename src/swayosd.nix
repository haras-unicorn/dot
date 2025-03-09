{ pkgs, lib, config, ... }:

# TODO: colors

let
  hasMonitor = config.dot.hardware.monitor.enable;
  hasWayland = config.dot.hardware.graphics.wayland;
in
{
  branch.nixosModule.nixosModule = lib.mkIf (hasMonitor && hasWayland) {
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

  branch.homeManagerModule.homeManagerModule = lib.mkIf (hasMonitor && hasWayland) {
    services.swayosd.enable = true;
    services.swayosd.display = config.dot.hardware.monitor.main;
  };
}
