{
  machines.homeModules.swaybg =
    {
      lib,
      config,
      osConfig,
      pkgs,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;
    in
    lib.mkIf (hardware.graphics && hardware.wayland) {
      home.packages = [ pkgs.swaybg ];

      systemd.user.services.swaybg = {
        Install.WantedBy = [ "graphical-session.target" ];
        Unit.PartOf = [ "graphical-session.target" ];
        Unit.After = [ "graphical-session-pre.target" ];
        Service.ExecStart = "${lib.getExe pkgs.swaybg} -i ${lib.escapeShellArg osConfig.dot.wallpaper.image} -m fill";
      };
    };
}
