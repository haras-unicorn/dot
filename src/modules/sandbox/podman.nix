{
  machines.nixosModules.podman = { config, pkgs, ... }: {
    virtualisation.containers.enable = true;

    virtualisation.podman = {
      enable = true;
      autoPrune.enable = true;
      defaultNetwork.settings.dns_enabled = true;

      dockerSocket.enable = true;
      dockerCompat = true;
    };

    users.users.${config.dot.user.user}.extraGroups = [
      "podman"
    ];
  };

  machines.homeModules.podman = { lib, pkgs, ... }: {
    dot.programs.shell.aliases = {
      lp = lib.getExe pkgs.lazydocker;
    };

    home.packages = [
      pkgs.lazydocker
      pkgs.docker-client
      pkgs.docker-compose
    ];
  };
}
