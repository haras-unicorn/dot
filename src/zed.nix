{ config, lib, ... }:

let
  hasMonitor = config.dot.hardware.monitor.enable;
  hasKeyboard = config.dot.hardware.keyboard.enable;
in
{
  branch.homeManagerModule.homeManagerModule = lib.mkIf (hasMonitor && hasKeyboard) {
    programs.zed-editor.enable = true;
    programs.zed-editor.extensions = [
      "toml"
      "marksman"
      "html"
      "scss"
      "just"
      "nu"
      "csharp"
      "pylsp"
      "ruff"
    ];
    programs.zed-editor.userSettings = {
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
