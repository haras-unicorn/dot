{ pkgs, config, lib, ... }:

# TODO: grub theming
# TODO: use iso generator and put firmware on sd card for rpi 4
# TODO: laptop battery saving

let
  hasMonitor = config.dot.hardware.monitor.enable;
  isRpi4 = config.dot.hardware.rpi."4".enable;
  isLegacyNvidia =
    let
      version = config.dot.hardware.graphics.version;
      driver = config.dot.hardware.graphics.driver;
    in
    driver == "nvidia"
    && ((version != "latest")
    && (version != "production"));
in
{
  system = {
    boot.loader.efi.canTouchEfiVariables = false;
    boot.loader.grub.enable = !isRpi4;
    boot.loader.grub.device = "nodev";
    boot.loader.grub.efiSupport = true;
    boot.loader.grub.useOSProber = true;
    boot.loader.generic-extlinux-compatible.enable = isRpi4;

    boot.binfmt.emulatedSystems = (lib.mkIf
      (pkgs.system == "x86_64-linux")
      [ "aarch64-linux" ]);

    boot.kernelPackages =
      if isRpi4 then pkgs.linuxKernel.packages.linux_rpi4
      else if isLegacyNvidia then pkgs.linuxKernel.packages.linux_6_6
      else pkgs.linuxPackages_zen;
    services.ananicy.enable = true;
    services.ananicy.packages = pkgs.ananicy-cpp;
    services.preload.enable = true;

    boot.initrd.kernelModules = [
      "ext4"
      "vfat"
    ];
    fileSystems."/firmware" = lib.mkIf isRpi4 {
      device = "/dev/disk/by-label/FIRMWARE";
      fsType = "vfat";
    };
    fileSystems."/boot" = lib.mkIf (!isRpi4) {
      device = "/dev/disk/by-label/NIXBOOT";
      fsType = "vfat";
    };
    fileSystems."/" = lib.mkMerge [
      (lib.mkIf (!isRpi4) {
        device = "/dev/disk/by-label/NIXROOT";
        fsType = "ext4";
      })
      (lib.mkIf (isRpi4) {
        device = "/dev/disk/by-label/NIXOS_SD";
        fsType = "ext4";
      })
    ];
    swapDevices = [{
      device = "/var/swap";
      size = config.dot.hardware.memory / 1000 / 1000;
    }];
    services.fstrim.enable = true;

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
