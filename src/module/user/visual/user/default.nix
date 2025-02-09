{ pkgs, config, lib, ... }:

let
  hasMonitor = config.dot.hardware.monitor.enable;
  hasKeyboard = config.dot.hardware.keyboard.enable;
in
{
  home = lib.mkIf (hasMonitor && hasKeyboard) {
    home.packages = [
      pkgs.zed-editor
    ];

    xdg.configFile."zed/settings.json".text = builtins.toJSON {
      autosave = "on_window_change";
      vim_mode = true;
      load_direnv = "direct";
      inline_completions = {
        disabled_globs = [
          ".env"
        ];
      };
      tab_bar = {
        show = false;
      };
      toolbar = {
        breadcrumbs = true;
        quick_actions = true;
      };
      inlay_hints = {
        enabled = true;
      };
      wrap_guides = [ 80 120 ];
      tab_size = 2;
      telemetry = {
        diagnostics = true;
        metrics = false;
      };
      terminal = {
        shell = {
          program = "${config.dot.shell.package}/bin/${config.dot.shell.bin}";
        };
        detect_venv = "off";
        button = false;
      };
      project_panel = {
        button = false;
      };
      outline_panel = {
        button = false;
      };
    };
  };
}
