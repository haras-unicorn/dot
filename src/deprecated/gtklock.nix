{
  self.lib.deprecated.nixosModules.gtklock =
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
      security.pam.services.gtklock = { };
      services.systemd-lock-handler.enable = true;

      systemd.user.services.gtklock = {
        description = "GTK Lock Service";
        wantedBy = [
          "lock.target"
          "sleep.target"
        ];
        before = [ "sleep.target" ];
        script = "${pkgs.gtklock}/bin/gtklock";
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
      };
    };

  self.lib.deprecated.homeModules.gtklock =
    {
      pkgs,
      lib,
      osConfig,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;
    in
    lib.mkIf (hardware.visual && hardware.wayland) {
      home.packages = [
        pkgs.gtklock
      ];

      services.swayidle.events = {
        lock = "${pkgs.gtklock}/bin/gtklock -d";
        before-sleep = "${pkgs.gtklock}/bin/gtklock -d";
      };
    };
}
