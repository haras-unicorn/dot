{
  self.nixosModules.tuigreet.value =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    let
      theme = "border=magenta;text=cyan;prompt=green;time=red;action=blue;button=yellow;container=black;input=red";
      hardware = config.dot.hardware;
    in
    lib.mkIf (hardware.visual && hardware.wayland) {
      dot.desktop.login =
        lib.getExe pkgs.tuigreet
        + " --sessions '${config.dot.desktop.sessions}/share/wayland-sessions'"
        + " --user-menu"
        + " --theme '${theme}'"
        + " --asterisks"
        + " --remember"
        + " --remember-user-session";

      # This directory is not configurable in tuigreet, so if tuigreet changes it,
      # this breaks.
      stolon.keep.directories = [ "/var/cache/tuigreet" ];
    };
}
