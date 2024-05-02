{ pkgs, ... }:

{
  system = {
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
    boot.plymouth.theme = "nixos-bgrt";
    boot.plymouth.themePackages = with pkgs; [
      nixos-bgrt-plymouth
    ];
  };
}
