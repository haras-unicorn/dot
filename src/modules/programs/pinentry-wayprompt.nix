{
  self.nixosModules.pinentry-wayprompt.value =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      hardware = config.dot.hardware;

      package =
        if hardware.graphics then
          if hardware.wayland then pkgs.wayprompt else pkgs.pinentry-qt
        else
          pkgs.pinentry-curses;
    in
    {
      options.dot = {
        pinentry = {
          package = lib.mkOption {
            type = lib.types.package;
            internal = true;
          };
        };
      };

      config = {
        dot.pinentry.package = package;

        dot.commands.pinentry = config.dot.pinentry.package;
      };
    };

  self.homeModules.pinentry-wayprompt.value =
    {
      osConfig,
      lib,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;
    in
    {
      programs.wayprompt = lib.mkIf (hardware.wayland && hardware.graphics) {
        enable = true;
        package = osConfig.dot.pinentry.package;
      };
    };
}
