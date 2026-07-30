{
  self.lib.deprecated.homeModules.kitty =
    {
      config,
      osConfig,
      lib,
      pkgs,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;

      cfg = config.dot.programs.terminal;

      vars = lib.strings.concatStringsSep "\n" (
        builtins.map (name: "env ${name}=${builtins.toString cfg.sessionVariables."${name}"}") (
          builtins.attrNames cfg.sessionVariables
        )
      );
    in
    lib.mkIf hardware.visual {
      dot.programs.terminal.package = config.programs.kitty.package;

      stylix.targets.kitty.variant256Colors = true;

      programs.kitty.enable = true;
      programs.kitty.extraConfig = ''
        cursor_shape beam
        cursor_blink_interval 0
        enable_audio_bell no

        shell ${lib.getExe config.dot.programs.shell.package}
        editor ${lib.getExe config.dot.programs.editor.package}

        ${vars}
      '';
    };
}
