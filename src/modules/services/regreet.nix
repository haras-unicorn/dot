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
      cfg = config.dot.desktop;

      package = pkgs.symlinkJoin {
        name = "regreet";
        paths = [ pkgs.regreet ];
        buildInputs = [ pkgs.makeWrapper ];
        version = pkgs.regreet.version;
        meta.mainProgram = "regreet";
        postBuild = ''
          wrapProgram $out/bin/regreet \
            --set XDG_DATA_DIRS "${cfg.sessions}/share"
        '';
      };
    in
    lib.mkIf (hardware.visual && hardware.wayland) {
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
      programs.regreet.settings.skip_selection = true;
    };
}
