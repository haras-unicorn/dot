{ pkgs, config, lib, ... }:

let
  hasMonitor = config.dot.hardware.monitor.enable;
in
{
  system = {
    boot.loader.efi.canTouchEfiVariables = false;
    boot.loader.grub.enable = true;
    boot.loader.grub.device = "nodev";
    boot.loader.grub.efiSupport = true;
    boot.loader.grub.useOSProber = true;

    boot.kernelPackages = pkgs.linuxPackages;

    fileSystems."/boot" = {
      device = "/dev/disk/by-label/NIXBOOT";
      fsType = "vfat";
    };
    fileSystems."/" = {
      device = "/dev/disk/by-label/NIXROOT";
      fsType = "ext4";
    };
    swapDevices = [{
      device = "/var/swap";
      size = config.dot.hardware.memory / 1000 / 1000;
    }];

    boot.initrd.systemd.enable = lib.mkIf hasMonitor true;
    boot.initrd.verbose = lib.mkIf hasMonitor false;
    boot.consoleLogLevel = lib.mkIf hasMonitor 0;
    boot.kernelParams = lib.mkIf hasMonitor [
      "quiet"
      "splash"
      "boot.shell_on_fail"
      "vt.global_cursor_default=0"
      "loglevel=3"
      "rd.systemd.show_status=false"
      "rd.udev.log_level=3"
      "udev.log_priority=3"
    ];
    boot.plymouth.enable = lib.mkIf hasMonitor true;
    boot.plymouth.theme = lib.mkIf hasMonitor "nixos-bgrt";
    boot.plymouth.themePackages = lib.mkIf hasMonitor [
      pkgs.nixos-bgrt-plymouth
    ];
  };
}
