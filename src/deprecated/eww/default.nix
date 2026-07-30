{
  self.lib.deprecated.homeModules.eww =
    {
      config,
      lib,
      osConfig,
      pkgs,
      ...
    }:
    let
      package = pkgs.eww;

      hardware = osConfig.dot.hardware;
    in
    lib.mkIf hardware.browser {
      systemd.user.services.eww = {
        Unit.Description = "Eww daemon";
        Service.ExecStart = "${lib.getExe package} daemon";
        Unit.Requires = [ "graphical-session.target" ];
        Unit.After = [ "graphical-session.target" ];
        Install.WantedBy = [ "graphical-session.target" ];
      };

      home.packages = [
        package
      ];

      programs.eww.enable = true;
      programs.eww.package = package;
      programs.eww.configDir = ./config;
    };
}
