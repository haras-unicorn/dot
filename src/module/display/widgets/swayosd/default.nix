{ pkgs, lib, config, ... }:

# NOTE: https://github.com/NixOS/nixpkgs/issues/280041#issuecomment-1951437276

let
  hasMonitor = config.dot.hardware.monitor.enable;
  hasWayland = config.dot.hardware.graphics.wayland;
in
{
  system = lib.mkIf (hasMonitor && hasWayland) {
    environment.systemPackages = [ pkgs.swayosd ];
    services.udev.packages = [ pkgs.swayosd ];
  };

  home = lib.mkIf (hasMonitor && hasWayland) {
    services.swayosd.enable = true;
    services.swayosd.display = config.dot.hardware.monitor.main;

    systemd.user.services.swayosd-libinput-backend = {
      Unit = {
        Description = "SwayOSD LibInput backend for listening to certain keys like CapsLock, ScrollLock, VolumeUp, etc.";
        Documentation = [ "https://github.com/ErikReider/SwayOSD" ];
        WantedBy = [ "graphical.target" ];
        PartOf = [ "graphical.target" ];
        After = [ "graphical.target" ];
      };

      ServiceConfig = {
        Type = "dbus";
        BusName = "org.erikreider.swayosd";
        ExecStart = "${pkgs.swayosd}/bin/swayosd-libinput-backend";
        Restart = "on-failure";
      };
    };
  };
}
