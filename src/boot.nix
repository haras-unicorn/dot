{
  pkgs,
  config,
  lib,
  ...
}:

# TODO: grub theming

let
  hasMonitor = config.dot.hardware.monitor.enable;
  isRpi4 = config.dot.hardware.rpi."4".enable;
  isLegacyNvidia =
    let
      version = config.dot.hardware.graphics.version;
      driver = config.dot.hardware.graphics.driver;
    in
    driver == "nvidia" && ((version != "latest") && (version != "production"));
in
{
  branch.nixosModule.nixosModule = {
    boot.loader.efi.canTouchEfiVariables = false;
    boot.loader.grub.enable = !isRpi4;
    boot.loader.grub.device = "nodev";
    boot.loader.grub.efiSupport = true;
    boot.loader.grub.useOSProber = true;
    boot.loader.generic-extlinux-compatible.enable = isRpi4;

    boot.binfmt.preferStaticEmulators = true;
    boot.binfmt.emulatedSystems = (lib.mkIf (pkgs.system == "x86_64-linux") [ "aarch64-linux" ]);

    boot.kernelPackages =
      if isRpi4 then
        pkgs.linuxKernel.packages.linux_rpi4
      else if isLegacyNvidia then
        pkgs.linuxKernel.packages.linux_6_6
      else
        # FIXME: https://github.com/NixOS/nixpkgs/issues/429624#issuecomment-3148696289
        pkgs.linuxKernel.packages.linux_6_15;
        # pkgs.linuxPackages_zen;

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
