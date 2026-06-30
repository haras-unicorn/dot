# FIXME: startup options not showing
# TODO: default startup option as first

{
  machines.nixosModules.regreet =
    {
      lib,
      config,
      pkgs,
      flake,
      ...
    }:
    let
      hardware = config.dot.hardware;

      # https://github.com/rharish101/ReGreet/blob/c75486b2e1f3f5e1a30a93c2df050df2b5d61b9f/src/sysutil.rs#L146
      package = pkgs.symlinkJoin {
        name = "regreet";
        paths = [ pkgs.regreet ];
        buildInputs = [ pkgs.makeWrapper ];
        version = pkgs.regreet.version;
        meta.mainProgram = "regreet";
        postBuild = ''
          wrapProgram $out/bin/regreet \
            --set SESSION_DIRS "${config.dot.desktop.sessions}" \
            --unset XDG_DATA_DIRS
        '';
      };
    in
    lib.mkIf (hardware.visual && hardware.wayland) {
      # NOTE: force because still keeping tuigreet config for now
      dot.desktop.login = lib.mkForce (
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
