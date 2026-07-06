{
  self.lib.deprecated.nixosModules.docker =
    {
      pkgs,
      config,
      ...
    }:
    let
      user = config.dot.user.user;
    in
    {
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
    };
}
