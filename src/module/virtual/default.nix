{ pkgs
, config
, ...
}:

# FIXME: https://github.com/NixOS/nixpkgs/pull/303442
# FIXME: podman OCI runtime error
# FIXME: gns3 bridge fails restarting
# TODO: use podman when starship support
# TODO: use docker rootless when networking becomes less of a pain
# TODO: wine packages

let
  bridgeGns3 =
    let
      prefix = 24;
      address = "10.10.10.1";
    in
    {
      inherit address prefix;
      name = "br-gns3";
      subnet = "${address}/${builtins.toString prefix}";
    };
in
{
  system = {
    environment.systemPackages = with pkgs; [
      lazydocker
      docker-client
      docker-compose
      gns3-gui
    ];

    # virtualisation.podman.enable = true;
    # virtualisation.podman.dockerSocket.enable = true;
    # virtualisation.podman.autoPrune.enable = true;
    # virtualisation.podman.defaultNetwork.settings.dns_enabled = true;
    # virtualisation.oci-containers.backend = "podman";

    virtualisation.docker.enable = true;
    virtualisation.docker.autoPrune.enable = true;
    # virtualisation.docker.rootless.enable = true;
    # virtualisation.docker.rootless.setSocketVariable = true;

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

    # systemd.services."${bridgeGns3.name}-setup" = {
    #   description = "Setup ${bridgeGns3.name} interface";
    #   after = [ "network.target" ];
    #   wantedBy = [ "multi-user.target" ];
    #   script = ''
    #     ${pkgs.iproute2}/bin/ip link add name ${bridgeGns3.name} type bridge
    #     ${pkgs.iproute2}/bin/ip addr add ${bridgeGns3.subnet} dev ${bridgeGns3.name}
    #     ${pkgs.iproute2}/bin/ip link set ${bridgeGns3.name} up
    #   '';
    #   preStop = ''
    #     ${pkgs.iproute2}/bin/ip link set ${bridgeGns3.name} down
    #     ${pkgs.iproute2}/bin/ip addr del ${bridgeGns3.subnet} dev ${bridgeGns3.name}
    #     ${pkgs.iproute2}/bin/ip link del ${bridgeGns3.name}
    #   '';
    #   serviceConfig = {
    #     Type = "oneshot";
    #     RemainAfterExit = true;
    #   };
    # };
  };
}
