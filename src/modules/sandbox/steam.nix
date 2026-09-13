{
  self.nixpkgs.config.allowUnfreePackageNames = [
    "steam"
    "steam-unwrapped"
  ];

  self.nixosModules.steam.value =
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
      programs.steam.enable = true;
      programs.steam.protontricks.enable = true;
      # NOTE: bitburner
      programs.steam.extraPackages = [
        pkgs.nss
      ];
    };

  self.homeModules.steam.value =
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
