{
  machines.nixosModules.rpi4 =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    lib.mkIf (config.dot.hardware.deviceType == "rpi4") {
      nixpkgs.overlays = (
        final: prev: {
          # NOTE: https://github.com/NixOS/nixpkgs/issues/154163#issuecomment-1008362877
          makeModulesClosure = x: prev.makeModulesClosure (x // { allowMissing = true; });
        }
      );

      boot.kernelPackages = lib.mkForce pkgs.linuxKernel.packages.linux_rpi4;

      fileSystems."/boot".enable = false;
      fileSystems."/" = lib.mkForce {
        device = "/dev/disk/by-label/NIXOS_SD";
        fsType = "ext4";
      };
      fileSystems."/firmware" = {
        device = "/dev/disk/by-label/FIRMWARE";
        fsType = "vfat";
      };

      swapDevices = lib.mkForce [ ];
      zramSwap.enable = true;

      boot.loader.grub.enable = lib.mkForce false;
      boot.loader.generic-extlinux-compatible.enable = true;

      environment.systemPackages = with pkgs; [
        libraspberrypi
        raspberrypi-eeprom
      ];
    };
}
