{ pkgs
, config
  # , hardware
, ...
}:

{
  environment.systemPackages = with pkgs; [
    wineWowPackages.stable
    lutris
    virt-manager
    spice
    spice-vdagent
    virglrenderer
    win-virtio
    win-spice
    lazydocker
    docker-client
    docker-compose
    podman-desktop
    arion
  ];

  services.qemuGuest.enable = true;
  virtualisation.libvirtd.enable = true;
  virtualisation.libvirtd.qemu.package = pkgs.qemu_kvm;
  virtualisation.libvirtd.qemu.ovmf.enable = true;
  virtualisation.libvirtd.qemu.ovmf.packages = [ pkgs.OVMFFull.fd ];
  virtualisation.libvirtd.qemu.swtpm.enable = true;
  # NOTE: secure boot
  environment.etc = {
    "ovmf/edk2-x86_64-secure-code.fd" = {
      source = config.virtualisation.libvirtd.qemu.package + "/share/qemu/edk2-x86_64-secure-code.fd";
    };

    "ovmf/edk2-i386-vars.fd" = {
      source = config.virtualisation.libvirtd.qemu.package + "/share/qemu/edk2-i386-vars.fd";
    };
  };

  virtualisation.podman.enable = true;
  virtualisation.podman.dockerSocket.enable = true;
  virtualisation.podman.autoPrune.enable = true;
  virtualisation.podman.defaultNetwork.settings.dns_enabled = true;

  services.cockpit.enable = true;
  services.packagekit.enable = true;

  programs.steam.enable = true;

  # FIXME: https://github.com/NixOS/nixpkgs/issues/127404
  # virtualisation.xen.enable = true;
  # virtualisation.xen.domain0MemorySize = (hardware.ram * 3 / 4) / 1024;
}
