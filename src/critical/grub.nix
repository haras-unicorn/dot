{
  config,
  ...
}:

# TODO: theming

let
  isRpi4 = config.dot.hardware.rpi."4".enable;
in
{
  nixosModule = {
    boot.loader.efi.canTouchEfiVariables = false;
    boot.loader.grub.enable = !isRpi4;
    boot.loader.grub.device = "nodev";
    boot.loader.grub.efiSupport = true;
    boot.loader.grub.useOSProber = true;
    boot.loader.generic-extlinux-compatible.enable = isRpi4;

    stylix.targets.grub.useWallpaper = true;
  };
}
