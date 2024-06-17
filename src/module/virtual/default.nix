{ pkgs
, config
, ...
}:

# FIXME: https://github.com/NixOS/nixpkgs/pull/303442
# FIXME: podman OCI runtime error
# TODO: use podman when starship support

let
  tap0 = rec {
    name = "tap0";
    prefix = 24;
    address = "10.10.10.1";
    subnet = "${address}/${builtins.toString prefix}";
  };
in
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

    networking.interfaces.tap0 = {
      ipv4.addresses = [
        {
          address = tap0.subnet;
          prefixLength = tap0.prefix;
        }
      ];
    };
    systemd.services.tap0-setup = {
      description = "Setup TAP0 interface";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStartPre = [
          "${pkgs.iproute2}/bin/ip tuntap add dev tap0 mode tap"
          "${pkgs.iproute2}/bin/ip link set tap0 up"
          "${pkgs.iproute2}/bin/ip addr add ${tap0.subnet} dev tap0"
        ];
        ExecStart = "${pkgs.coreutils}/bin/sleep infinity";
        ExecStop = [
          "${pkgs.iproute2}/bin/ip link set tap0 down"
          "${pkgs.iproute2}/bin/ip tuntap del dev tap0 mode tap"
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
