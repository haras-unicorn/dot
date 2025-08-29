{
  pkgs,
  lib,
  config,
  ...
}:

# FIXME: fullscreen detection

let
  hasMonitor = config.dot.hardware.monitor.enable;
  hasWayland = config.dot.hardware.graphics.wayland;

  mkCallback =
    name: command:
    let
      package = pkgs.writeShellApplication {
        inherit name;
        text = ''
          if ! ( ${config.dot.desktopEnvironment.fullscreenCheck} ); then
            exec ${command}
          fi
        '';
      };
    in
    {
      inherit name package;
      command = "${package}/bin/${name}";
    };

  lockCallback = mkCallback "swayidle-lock" "${pkgs.systemd}/bin/loginctl lock-session";
  suspendCallback = mkCallback "swayidle-suspend" "${pkgs.systemd}/bin/systemctl suspend-then-hibernate";
in
{
  branch.homeManagerModule.homeManagerModule = lib.mkIf (hasMonitor && hasWayland) {
    home.packages = [
      lockCallback.package
      suspendCallback.package
    ];

    services.swayidle.enable = true;
    services.swayidle.timeouts = [
      {
        timeout = 60 * 5;
        command = lockCallback.command;
      }
      {
        timeout = 60 * 60;
        command = suspendCallback.command;
      }
    ];
  };
}
