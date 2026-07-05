{
  machines.nixosModules.grub = {
    boot.loader.efi.canTouchEfiVariables = false;
    boot.loader.grub.enable = true;
    boot.loader.grub.device = "nodev";
    boot.loader.grub.efiSupport = true;
    boot.loader.grub.useOSProber = true;
    boot.loader.grub.efiInstallAsRemovable = true;
    stylix.targets.grub.useWallpaper = true;
  };
}
