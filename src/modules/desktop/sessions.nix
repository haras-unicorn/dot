{
  machines.nixosModules.sessions =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.dot.desktop;

      sessions = pkgs.runCommand "sessions" { } (
        let
          desktopFile = s: ''
            cat > $out/share/${s.type}-sessions/${lib.strings.escapeShellArg s.name}.desktop <<'EOF'
            [Desktop Entry]
            Name=${s.name}
            Comment=Launch ${s.name}
            Exec=/usr/bin/env ${s.command}
            Type=Application
            EOF
          '';
        in
        ''
          mkdir -p $out/share/wayland-sessions
          mkdir -p $out/share/xsessions
          ${lib.concatStringsSep "\n" (map desktopFile cfg.startup)}
        ''
      );
    in
    {
      dot.desktop.sessions = sessions;
    };
}
