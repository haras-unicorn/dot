{ pkgs
, config
, ...
}:

# FIXME: https://github.com/NixOS/nixpkgs/pull/303442
# FIXME: podman OCI runtime error
# TODO: use podman when starship support

let
  bridgeGns3 = rec {
    name = "br-gns3";
    prefix = 24;
    address = "10.10.10.1";
    subnet = "${address}/${builtins.toString prefix}";
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

    networking.bridges.${bridgeGns3.name}.interfaces = [ ];
    networking.interfaces.${bridgeGns3.name}.ipv4.addresses = [
      {
        address = bridgeGns3.address;
        prefixLength = bridgeGns3.prefix;
      }
    ];
    systemd.services."${bridgeGns3.name}-setup" = {
      description = "Setup ${bridgeGns3.name} interface";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      script = ''
        ${pkgs.iproute2}/bin/ip link add name ${bridgeGns3.name} type bridge
        ${pkgs.iproute2}/bin/ip addr add ${bridgeGns3.subnet} dev ${bridgeGns3.name}
        ${pkgs.iproute2}/bin/ip link set ${bridgeGns3.name} up
      '';
      preStop = ''
        ${pkgs.iproute2}/bin/ip link set ${bridgeGns3.name} down
        ${pkgs.iproute2}/bin/ip addr del ${bridgeGns3.subnet} dev ${bridgeGns3.name}
        ${pkgs.iproute2}/bin/ip link del ${bridgeGns3.name}
      '';
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
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
