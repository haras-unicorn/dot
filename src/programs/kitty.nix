{
  pkgs,
  lib,
  config,
  ...
}:

let
  hasMonitor = config.dot.hardware.monitor.enable;
  hasKeyboard = config.dot.hardware.keyboard.enable;

  cfg = config.dot.terminal;

  vars = lib.strings.concatStringsSep "\n" (
    builtins.map (name: "env ${name}=${builtins.toString cfg.sessionVariables."${name}"}") (
      builtins.attrNames cfg.sessionVariables
    )
  );

  shell = config.dot.shell;
  editor = config.dot.editor;
in
{
  homeManagerModule = {
    dot.terminal = {
      package = pkgs.kitty;
      bin = "kitty";
    };

    stylix.targets.kitty.variant256Colors = true;

    programs.kitty.enable = true;
    programs.kitty.extraConfig = lib.mkIf (hasKeyboard && hasMonitor) ''
      cursor_shape beam
      cursor_blink_interval 0
      enable_audio_bell no

      shell ${shell.package}/bin/${shell.bin}
      editor  ${editor.package}/bin/${editor.bin}

      ${vars}
    '';
  };
}
