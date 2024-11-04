{ pkgs, lib, config, ... }:

# TODO: use window rules from dot config

let
  bootstrap = config.dot.colors.bootstrap;

  hasMonitor = config.dot.hardware.monitor.enable;
  hasWayland = config.dot.hardware.graphics.wayland;
in
{
  home = lib.mkIf (hasMonitor && !hasWayland) {
    home.activation = {
      picomReloadAction = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        ${pkgs.procps}/bin/pkill --signal "SIGUSR1" "picom" || true
      '';
    };

    services.picom.enable = true;
    services.picom.settings = lib.mkForce { };

    xdg.configFile."picom/picom.conf".text = ''
      ${builtins.readFile ./picom.conf}

      shadow-color = "${bootstrap.background.normal.hex}";
    '';
  };
}
