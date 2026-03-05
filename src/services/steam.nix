{
  flake.nixosModules.services-steam =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      hasMonitor = config.dot.hardware.monitor.enable;
      hasMouse = config.dot.hardware.mouse.enable;
      hasKeyboard = config.dot.hardware.keyboard.enable;
    in
    {
      config = lib.mkIf (hasMonitor && hasMouse && hasKeyboard) {
        programs.steam.enable = true;
        programs.steam.protontricks.enable = true;
        programs.steam.extraCompatPackages = [
          pkgs.proton-ge-bin
        ];
        # NOTE: bitburner
        programs.steam.extraPackages = [
          pkgs.nss
        ];
      };
    };

  flake.homeModules.services-steam =
    {
      pkgs,
      config,
      lib,
      osConfig,
      ...
    }:
    let
      hasMonitor = config.dot.hardware.monitor.enable;
      hasMouse = config.dot.hardware.mouse.enable;
      hasKeyboard = config.dot.hardware.keyboard.enable;
    in
    {
      config = lib.mkIf (hasMonitor && hasMouse && hasKeyboard) {
        dot.desktopEnvironment.windowrules = [
          {
            rule = "float";
            selector = "class";
            arg = "steam";
          }
        ];

        systemd.user.services.steam = {
          Unit.Description = "Steam daemon";
          Service.ExecStart = "${pkgs.steam}/bin/steam -nochatui -nofriendsui -silent";
          Unit.After = [ "graphical-session.target" ];
          Unit.Requires = [ "graphical-session.target" ];
          Install.WantedBy = [ "graphical-session.target" ];
        };

        programs.lutris.steamPackage = osConfig.programs.steam.package;
      };
    };
}
