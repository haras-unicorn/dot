{ selfLib, ... }:

{
  machines.homeModules.zed =
    {
      osConfig,
      config,
      pkgs,
      lib,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;

      package = config.programs.zed-editor.package;

      source = pkgs.writeShellApplication {
        name = "zed-editor-source";
        runtimeInputs = [ package ];
        text = ''
          tmp="$(mktemp)"
          trap 'rm -f "$tmp"' EXIT
          zeditor --foreground -n "$tmp" &>/dev/null
          cat "$tmp"
        '';
      };

      node = pkgs.writeShellApplication {
        name = "zed-editor-node";
        runtimeInputs = [ package ];
        text = ''
          tmp="$(mktemp)"
          trap 'rm -f "$tmp"' EXIT
          cat > "$tmp"
          zeditor --foreground -n "$tmp" &>/dev/null
        '';
      };
    in
    lib.mkIf hardware.visual {
      dot.programs.visual.package = package;

      dot.processing = {
        sources.zed-editor = {
          note = "Write text";
          tags = [
            "text"
            "write"
          ];
          output = "detect";
          package = source;
        };
        nodes.zed-editor = {
          note = "Edit text";
          tags = [
            "text"
            "editor"
          ];
          inputs = selfLib.mime.editor;
          output = "detect";
          package = node;
        };
      };

      programs.zed-editor.enable = true;
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
      programs.zed-editor.userSettings = {
        agent = {
          button = false;
          version = "2";
        };
        autosave = "on_window_change";
        collaboration_panel.button = false;
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
          shell.program = lib.getExe config.dot.programs.shell.package;
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
