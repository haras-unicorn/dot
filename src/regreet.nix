{
  lib,
  config,
  pkgs,
  ...
}:

let
  hasMonitor = config.dot.hardware.monitor.enable;
  hasWayland = config.dot.hardware.graphics.wayland;
  hasKeyboard = config.dot.hardware.keyboard.enable;

  package = pkgs.symlinkJoin {
    name = "regreet";
    paths = [ pkgs.greetd.regreet ];
    buildInputs = [ pkgs.makeWrapper ];
    version = pkgs.greetd.regreet.version;
    meta.mainProgram = "regreet";
    postBuild = ''
      wrapProgram $out/bin/regreet \
        --set SESSION_DIRS "${config.dot.desktopEnvironment.sessions}" \
        --unset XDG_DATA_DIRS
    '';
  };
in
{
  branch.nixosModule.nixosModule = lib.mkIf (hasMonitor && hasKeyboard && hasWayland) {
    # NOTE: force because still keeping tuigreet config for now
    dot.desktopEnvironment.login = lib.mkForce (
      (lib.getExe' pkgs.dbus "dbus-run-session")
      + " "
      + (lib.getExe pkgs.cage)
      + " "
      + (lib.escapeShellArgs config.programs.regreet.cageArgs)
      + " -- "
      + (lib.getExe config.programs.regreet.package)
    );

    programs.regreet.enable = true;
    programs.regreet.package = package;
  };
}
