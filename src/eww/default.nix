{
  pkgs,
  lib,
  config,
  ...
}:

# TODO: use instead of waybar
# TODO: hook up config like with waybar
# TODO: menues
# TODO: colors

let
  package = pkgs.eww;

  hasMonitor = config.dot.hardware.monitor.enable;
  hasWayland = config.dot.hardware.graphics.wayland;
  hasKeyboard = config.dot.hardware.keyboard.enable;
  hasMouse = config.dot.hardware.mouse.enable;
in
{
  branch.homeManagerModule.homeManagerModule =
    lib.mkIf (hasMonitor && hasKeyboard && hasMouse && hasWayland)
      {
        systemd.user.services.eww = {
          Unit = {
            Description = "Eww daemon";
            Requires = "tray.target";
            PartOf = [ "graphical-session.target" ];
            After = [ "graphical-session-pre.target" ];
          };
          Service.ExecStart = "${package}/bin/eww daemon";
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
