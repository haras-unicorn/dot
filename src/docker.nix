{ pkgs
, config
, ...
}:

# FIXME: https://github.com/NixOS/nixpkgs/pull/303442
# FIXME: podman OCI runtime error
# TODO: use podman when starship support
# TODO: use docker rootless when networking becomes less of a pain

let
  user = config.dot.user;
in
{
  branch.nixosModule.nixosModule = {
    environment.systemPackages = [
      pkgs.lazydocker
      pkgs.docker-client
      pkgs.docker-compose
    ];

    users.users.${user}.extraGroups = [
      "docker"
      "podman"
    ];

    virtualisation.docker.enable = true;
    virtualisation.docker.autoPrune.enable = true;

    # virtualisation.podman.enable = true;
    # virtualisation.podman.dockerSocket.enable = true;
    # virtualisation.podman.autoPrune.enable = true;
    # virtualisation.podman.defaultNetwork.settings.dns_enabled = true;
    # virtualisation.oci-containers.backend = "podman";

    # virtualisation.docker.rootless.enable = true;
    # virtualisation.docker.rootless.setSocketVariable = true;
  };
}
