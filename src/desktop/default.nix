{ ... }:

{
  flake.nixosModules.desktop =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.dot.desktopEnvironment;

      sessions = pkgs.runCommand "sessions" { } ''
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
    in
    {
      dot.desktopEnvironment.sessions = sessions;
    };
}
