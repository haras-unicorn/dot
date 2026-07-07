{
  machines.nixosModules.pinentry-wayprompt =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      hardware = config.dot.hardware;
    in
    {
      dot.programs.pinentry.package =
        if hardware.graphics then
          if hardware.wayland then pkgs.wayprompt else pkgs.pinentry-qt
        else
          pkgs.pinentry-curses;
    };

  machines.homeModules.pinentry-wayprompt =
    {
      osConfig,
      lib,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;
    in
    lib.mkIf (hardware.wayland && hardware.graphics) {
      programs.wayprompt.enable = true;
    };
}
