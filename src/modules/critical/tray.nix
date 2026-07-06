# NOTE: this is a somewhat dubious target in home-manager
# its hardcoded in a lot of modules and a lot of the time
# it is not necessary to configure services after/before it
{
  machines.homeModules.tray =
    {
      lib,
      osConfig,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;
    in
    lib.mkIf hardware.graphics {
      systemd.user.targets.tray = {
        Install.WantedBy = [ "graphical-session.target" ];
        Unit.PartOf = [ "graphical-session.target" ];
        Unit.After = [ "graphical-session.target" ];
      };
    };
}
