{ pkgs
, config
, ...
}:

# FIXME: podman OCI runtime error
# TODO: use podman when starship support

{
  system = {
    environment.systemPackages = with pkgs; [
      wineWowPackages.stable
      winetricks
      virt-manager
      spice
      spice-vdagent
      virglrenderer
      win-virtio
      win-spice
      lazydocker
      docker-client
      docker-compose
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

    # virtualisation.podman.enable = true;
    # virtualisation.podman.dockerSocket.enable = true;
    # virtualisation.podman.autoPrune.enable = true;
    # virtualisation.podman.defaultNetwork.settings.dns_enabled = true;
    # virtualisation.oci-containers.backend = "podman";

    virtualisation.docker.enable = true;
    virtualisation.docker.autoPrune.enable = true;
    virtualisation.docker.rootless.enable = true;
    virtualisation.docker.rootless.setSocketVariable = true;

    services.cockpit.enable = true;
    services.packagekit.enable = true;

    services.gns3-server.enable = true;
    services.gns3-server.ubridge.enable = true;
    services.gns3-server.vpcs.enable = true;
  };

  home = {
    shared = {
      home.packages = with pkgs; [
        gns3-gui
      ];
    };
  };
}
