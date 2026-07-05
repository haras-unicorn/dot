{
  self.lib.deprecated.nixosModules.tuigreet =
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
        "${pkgs.tuigreet}/bin/tuigreet"
        + " --sessions '${config.dot.desktop.sessions}'"
        + " --user-menu"
        + " --theme '${theme}'"
        + " --asterisks"
        + " --remember"
        + " --remember-user-session";
    };
}
