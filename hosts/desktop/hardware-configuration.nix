{ ... }:

{
  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "ahci"
    "usb_storage"
    "usbhid"
    "sd_mod"
    "sr_mod"
    "nvidia"
    "nvidia_modeset"
    "nvidia_uvm"
    "nvidia_drm"
  ];
  boot.kernelModules = [
    "kvm-amd"
  ];

  fileSystems."/" = {
    device = "/dev/disk/by-partlabel/nixroot";
    fsType = "ext4";
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-partlabel/nixboot";
    fsType = "vfat";
  };
  fileSystems."/archive" = {
    device = "dev/disk/by-label/Archive";
    fsType = "ntfs";
  };
  swapDevices = [
    {
      device = "/var/swap";
      size = 32 * 1024;
    }
  ];

  hardware.cpu.amd.updateMicrocode = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.opengl.enable = true;
  hardware.opengl.driSupport = true;
  hardware.opengl.driSupport32Bit = true;
  hardware.nvidia.modesetting.enable = true;

  environment.variables = {
    NVIDIA_BUS_ID = "31:0:0";
    NET_INTERFACE_ID = "enp27s0";
    CPU_SENSOR_TAG = "k10temp-pci-00c3";
  };

  programs.corectrl.enable = true;
  programs.corectrl.gpuOverclock.enable = true;
}
