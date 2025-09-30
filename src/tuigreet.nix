{
  pkgs,
  lib,
  config,
  ...
}:

let
  hasMonitor = config.dot.hardware.monitor.enable;
  hasWayland = config.dot.hardware.graphics.wayland;
  hasKeyboard = config.dot.hardware.keyboard.enable;

  cfg = config.dot.desktopEnvironment;

  sessions = pkgs.runCommand "tuigreet-sessions" { } ''
    mkdir -p $out
    ${lib.concatStringsSep "\n" (
      map (s: ''
        cat > $out/${lib.strings.escapeShellArg s.name}.desktop <<'EOF'
        [Desktop Entry]
        Name=${s.name}
        Comment=Launch ${s.name}
        Exec=/usr/bin/env ${s.command}
        Type=Application
        EOF
      '') cfg.startup
    )}
  '';

  theme = "border=magenta;text=cyan;prompt=green;time=red;action=blue;button=yellow;container=black;input=red";
in
{
  branch.nixosModule.nixosModule = lib.mkIf (hasMonitor && hasKeyboard && hasWayland) {
    dot.desktopEnvironment.login =
      "${pkgs.greetd.tuigreet}/bin/tuigreet"
      + " --sessions '${sessions}'"
      + " --user-menu"
      + " --theme '${theme}'"
      + " --asterisks"
      + " --remember"
      + " --remember-user-session";
  };
}
