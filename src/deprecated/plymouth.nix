{
  self.lib.deprecated.nixosModules.plymouth =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      hardware = config.dot.hardware;
    in
    {
      config = lib.mkIf hardware.graphics {
        boot.initrd.systemd.enable = true;
        boot.initrd.verbose = false;
        boot.consoleLogLevel = 0;
        boot.kernelParams = [
          "quiet"
          "splash"
          "boot.shell_on_fail"
          "vt.global_cursor_default=0"
          "loglevel=3"
          "rd.systemd.show_status=false"
          "rd.udev.log_level=3"
          "udev.log_priority=3"
        ];
        boot.plymouth.enable = true;
      };
    };
}
