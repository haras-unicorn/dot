{
  machines.nixosModules.gamemode =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      user = config.dot.user.user;

      hardware = config.dot.hardware;
    in
    lib.mkIf hardware.gaming {
      dot.programs.gamemode.package = pkgs.gamemode;

      programs.gamemode.enable = true;
      programs.gamemode.enableRenice = true;

      users.users.${user}.extraGroups = [
        "gamemode"
      ];

      programs.steam.extraPackages = [
        config.dot.programs.gamemode.package
      ];
    };

  machines.homeModules.gamemode =
    {
      osConfig,
      config,
      lib,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;
    in
    lib.mkIf hardware.gaming {
      programs.lutris.extraPackages = [
        osConfig.dot.programs.gamemode.package
      ];
    };
}
