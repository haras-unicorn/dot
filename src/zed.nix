{ config, pkgs, lib, unstablePkgs, ... }:

let
  hasMonitor = config.dot.hardware.monitor.enable;
  hasKeyboard = config.dot.hardware.keyboard.enable;
in
{
  branch.homeManagerModule.homeManagerModule = lib.mkIf (hasMonitor && hasKeyboard) {
    programs.zed-editor.enable = true;
    programs.zed-editor.package = unstablePkgs.zed-editor;
    programs.zed-editor.extensions = [
      "git-firefly"
      "env"
      "toml"
      "marksman"
      "html"
      "scss"
      "just"
      "nu"
      "csharp"
      "pylsp"
      "ruff"
      "nix"
    ];
    programs.zed-editor.extraPackages = [ pkgs.nixd ];
    programs.zed-editor.userSettings = {
      autosave = "on_window_change";
      helix_mode = true;
      load_direnv = "direct";
      edit_predictions = {
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
        metrics = true;
      };
      terminal = {
        shell.program = "${config.dot.shell.package}/bin/${config.dot.shell.bin}";
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
