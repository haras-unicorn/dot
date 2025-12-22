{
  pkgs,
  lib,
  config,
  ...
}:

let
  hasMonitor = config.dot.hardware.monitor.enable;
  hasWayland = config.dot.hardware.graphics.wayland;

  fullscreenCheck = pkgs.writeShellApplication {
    name = "fullscreen-check";
    runtimeInputs = builtins.attrValues config.dot.desktopEnvironment.fullscreenChecks;
    text = ''
      case "$XDG_CURRENT_DESKTOP" in
        ${lib.concatStringsSep "\n" (
          lib.mapAttrsToList (name: pkg: ''
            ${name})
              exec ${lib.getExe pkg}
              ;;
          '') config.dot.desktopEnvironment.fullscreenChecks
        )}
        *)
          echo "Unknown desktop environment: $XDG_CURRENT_DESKTOP" >&2
          exit 1
          ;;
      esac
    '';
  };

  mkCallback =
    name: command:
    let
      package = pkgs.writeShellApplication {
        inherit name;
        runtimeInputs = [
          pkgs.coreutils
          fullscreenCheck
        ];
        text = ''
          if ! ( fullscreen-check ); then
            exec ${command}
          fi
        '';
      };
    in
    {
      inherit name package;
      command = "${package}/bin/${name}";
      unwrapped = command;
    };

  lockCallback = mkCallback "swayidle-lock" "${pkgs.systemd}/bin/loginctl lock-session";
  suspendCallback = mkCallback "swayidle-suspend" "${pkgs.systemd}/bin/systemctl suspend-then-hibernate";
in
{
  homeManagerModule = lib.mkIf (hasMonitor && hasWayland) {
    home.packages = [
      fullscreenCheck
      lockCallback.package
      suspendCallback.package
    ];

    services.swayidle.enable = true;
    services.swayidle.timeouts = [
      {
        timeout = 60 * 3;
        command = lockCallback.command;
      }
      {
        timeout = 60 * 15;
        command = suspendCallback.command;
      }
      {
        timeout = 60 * 60;
        command = suspendCallback.unwrapped;
      }
    ];
  };
}
