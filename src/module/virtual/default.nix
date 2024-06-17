{ pkgs
, config
, ...
}:

# FIXME: https://github.com/NixOS/nixpkgs/pull/303442
# FIXME: podman OCI runtime error
# TODO: use podman when starship support

let
  tapGns3 = rec {
    name = "tap-gns3";
    prefix = 24;
    address = "10.10.10.1";
    subnet = "${address}/${builtins.toString prefix}";
  };

  bridgeGns3 = {
    name = "br-gns3";
  };
in
{
  system = {
    environment.systemPackages = with pkgs;
      [
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
        gns3-gui
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
    services.gns3-server.vpcs.enable = true;
    services.gns3-server.dynamips.enable = true;
    services.gns3-server.ubridge.enable = true;

    services.gns3-server.settings = {
      Server.ubridge_path = pkgs.lib.mkForce "/run/wrappers/bin/ubridge";
    };
    users.groups.gns3 = { };
    users.users.gns3 = {
      group = "gns3";
      isSystemUser = true;
    };
    systemd.services.gns3-server.serviceConfig = {
      User = "gns3";
      DynamicUser = pkgs.lib.mkForce false;
      NoNewPrivileges = pkgs.lib.mkForce false;
      RestrictSUIDSGID = pkgs.lib.mkForce false;
      PrivateUsers = pkgs.lib.mkForce false;
      UMask = pkgs.lib.mkForce "0022";
      DeviceAllow = [
        "/dev/net/tun rw"
        "/dev/net/tap rw"
      ] ++ pkgs.lib.optionals config.virtualisation.libvirtd.enable [
        "/dev/kvm"
      ];
    };

    networking.bridges.${bridgeGns3.name}.interfaces = [ tapGns3.name ];
    networking.interfaces.${bridgeGns3.name}.ipv4.addresses = [
      {
        address = bridgeGns3.subnet;
        prefixLength = bridgeGns3.prefix;
      }
    ];
    systemd.services."${bridgeGns3.name}-setup" = {
      description = "Setup ${bridgeGns3.name} interface";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStartPre = [
          "${pkgs.iproute2}/bin/ip link add name ${bridgeGns3.name} type bridge"
          "${pkgs.iproute2}/bin/ip link set ${bridgeGns3.name} up"
          "${pkgs.iproute2}/bin/ip tuntap add dev ${tapGns3.name} mode tap"
          "${pkgs.iproute2}/bin/ip addr add ${tapGns3.subnet} dev ${tapGns3.name}"
          "${pkgs.iproute2}/bin/ip link set ${tapGns3.name} up"
          "${pkgs.iproute2}/bin/ip link set ${tapGns3.name} master ${bridgeGns3.name}"
        ];
        ExecStart = "${pkgs.coreutils}/bin/sleep infinity";
        ExecStop = [
          "${pkgs.iproute2}/bin/ip link set ${tapGns3.name} nomaster"
          "${pkgs.iproute2}/bin/ip link set ${tapGns3.name} down"
          "${pkgs.iproute2}/bin/ip tuntap del dev ${tapGns3.name} mode tap"
          "${pkgs.iproute2}/bin/ip link set br-gns3 down"
          "${pkgs.iproute2}/bin/ip link del br-gns3"
        ];
      };
    };
  };

  home = {
    shared = {
      xdg.desktopEntries = {
        cockpit = {
          name = "Cockpit";
          exec = "${config.dot.browser.package}/bin/${config.dot.browser.bin} --new-window localhost:9090";
          terminal = false;
        };
      };
    };
  };
}
