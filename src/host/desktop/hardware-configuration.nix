{ self, hardware, ... }:

{
  imports = [
    "${self}/src/module/hardware/amd-cpu/amd-cpu.nix"
    "${self}/src/module/hardware/nvidia-gpu/nvidia-gpu.nix"
  ];

  hardware.enableAllFirmware = true;

  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "ahci"
    "usb_storage"
    "usbhid"
    "sd_mod"
    "sr_mod"
  ];

  fileSystems."/" = {
    device = "/dev/disk/by-partlabel/nixroot";
    fsType = "ext4";
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-partlabel/nixboot";
    fsType = "vfat";
  };

  swapDevices = [
    {
      device = "/var/swap";
      size = hardware.ram * 1024;
    }
  ];
}
