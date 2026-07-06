{
  machines.nixosModules.steam =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      hardware = config.dot.hardware;
    in
    lib.mkIf hardware.gaming {
      dot.nixpkgs.allowUnfreePredicates = [
        (
          package:
          let
            name = lib.getName package;
          in
          name == "steam" || name == "steam-unwrapped"
        )
      ];

      programs.steam.enable = true;
      programs.steam.protontricks.enable = true;
      # NOTE: bitburner
      programs.steam.extraPackages = [
        pkgs.nss
      ];
    };

  machines.homeModules.steam =
    {
      pkgs,
      config,
      lib,
      osConfig,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;
    in
    lib.mkIf hardware.gaming {
      dot.desktop.windowrules = [
        {
          rule = "float";
          selector = "class";
          arg = "steam";
        }
      ];

      systemd.user.services.steam = {
        Unit.Description = "Steam daemon";
        Service.ExecStart = "${lib.getExe osConfig.programs.steam.package} -nochatui -nofriendsui -silent";
        Install.WantedBy = [ "graphical-session.target" ];
        Unit.PartOf = [ "graphical-session.target" ];
        Unit.Requires = [ "tray.target" ];
        Unit.After = [
          "tray.target"
          "graphical-session.target"
        ];
      };

      programs.lutris.steamPackage = osConfig.programs.steam.package;
    };
}
