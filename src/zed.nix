{ config, pkgs, lib, unstablePkgs, rust-overlay, ... }:

let
  hasMonitor = config.dot.hardware.monitor.enable;
  hasKeyboard = config.dot.hardware.keyboard.enable;
in
{
  branch.homeManagerModule.homeManagerModule = lib.mkIf (hasMonitor && hasKeyboard) {
    nixpkgs.overlays = [
      (import rust-overlay)
      (final: prev: {
        rust-zed = prev.rust-bin.stable.latest.default.override {
          extensions = [
            "clippy"
            "rustfmt"
            "rust-analyzer"
            "rust-src"
          ];
          targets = [
            "wasm32-wasip2"
          ];
        };
      })
    ];

    programs.zed-editor.enable = true;
    programs.zed-editor.package = unstablePkgs.zed-editor;
    programs.zed-editor.extensions = [
      "git-firefly"
      "env"
      "log"
      "toml"
      "marksman"
      "html"
      "scss"
      "just"
      "nu"
      "pylsp"
      "ruff"
      "nix"
    ];
    programs.zed-editor.extraPackages = with pkgs; [
      nixd
      nil
      nixfmt-rfc-style
      package-version-server
      llvmPackages.clangNoLibcxx
      rust-zed
      rustup
    ];
    programs.zed-editor.userSettings = {
      agent = {
        button = false;
        version = "2";
      };
      autosave = "on_window_change";
      collaboration_panel.button = false;
      features.edit_prediction_provider = "supermaven";
      git_panel.button = false;
      gutter = {
        folds = false;
        line_numbers = false;
      };
      helix_mode = true;
      horizontal_scroll_margin = 100;
      inlay_hints = {
        enabled = true;
      };
      load_direnv = "direct";
      minimap.show = "auto";
      notification_panel = {
        button = false;
      };
      outline_panel = {
        button = false;
      };
      project_panel = {
        button = false;
        dock = "right";
        hide_gitignore = true;
      };
      search.button = false;
      tab_bar.show = false;
      tab_size = 2;
      telemetry = {
        diagnostics = true;
        metrics = true;
      };
      terminal = {
        button = false;
        detect_venv = "off";
        dock = "right";
        shell.program = "${config.dot.shell.package}/bin/${config.dot.shell.bin}";
        toolbar.breadcrumbs = false;
      };
      title_bar = {
        show_branch_icon = false;
        show_branch_name = false;
        show_onboarding_banner = false;
        show_project_items = false;
        show_sign_in = false;
        show_user_picture = false;
      };
      toolbar = {
        breadcrumbs = false;
        quick_actions = false;
      };
      vertical_scroll_margin = 100;
      wrap_guides = [ 80 ];

      lsp = {
        nil = {
          initialization_options = {
            formatting = {
              command = [ "nixfmt" ];
            };
          };
        };
      };
    };
  };
}
