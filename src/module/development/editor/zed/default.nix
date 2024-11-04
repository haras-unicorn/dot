{ pkgs, config, lib, ... }:

let
  bootstrap = config.dot.colors.bootstrap;
  terminal = config.dot.colors.terminal;
in
{
  home = lib.mkIf config.dot.hardware.monitor.enable {
    home.packages = [
      pkgs.zed-editor
    ];

    xdg.configFile."zed/settings.json".text = builtins.toJSON {
      autosave = "on_window_change";
      vim_mode = true;
      theme = {
        mode = if config.dot.colors.isLightTheme then "light" else "dark";
        light = "colors";
        dark = "colors";
      };
      buffer_font_family = config.dot.font.nerd.name;
      buffer_font_size = config.dot.font.size.medium;
      ui_font_size = config.dot.font.size.medium;
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
        font_family = config.dot.font.nerd.name;
        font_size = config.dot.font.size.small;
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

    xdg.configFile."zed/themes/colors.json".text = builtins.toJSON {
      name = "colors";
      author = "haras";
      themes = [{
        name = "colors";
        appearance = if config.dot.colors.isLightTheme then "light" else "dark";
        style = {
          "background.appearance" = "blurred";
          background = bootstrap.background.normal.hexa 00;
          "editor.background" = bootstrap.background.normal.hexa 33;
          "editor.gutter.background" = bootstrap.background.normal.hexa 33;
          "tab_bar.background" = bootstrap.background.normal.hexa 33;
          "terminal.background" = bootstrap.background.normal.hexa 33;
          "toolbar.background" = bootstrap.background.normal.hexa 33;
          "tab.active_background" = bootstrap.background.normal.hexa 55;
          "tab.inactive_background" = bootstrap.background.alternate.hexa 33;
          "status_bar.background" = bootstrap.background.normal.hexa 33;
          "title_bar.background" = bootstrap.background.normal.hexa 33;
          "panel.background" = bootstrap.background.normal.hexa 33;
          "surface.background" = bootstrap.background.normal.hexa 33;
          "ghost_element.background" = bootstrap.selection.alternate.hexa 66;
          "border.variant" = bootstrap.secondary.normal.hexa 00;
          "scrollbar.track.border" = bootstrap.secondary.normal.hexa 00;
          "editor.active_line.background" = bootstrap.background.alternate.hexa 00;

          border = bootstrap.primary.normal.hex;
          "editor.foreground" = bootstrap.text.normal.hex;
          "editor.line_number" = bootstrap.text.alternate.hex;
          "ghost_element.selected" = bootstrap.selection.normal.hex;
          "ghost_element.hover" = bootstrap.selection.normal.hex;
          syntax = {
            constant = {
              color = terminal.yellow.normal.hex;
              font_style = null;
              font_weight = null;
            };
            string = {
              color = terminal.green.normal.hex;
              font_style = null;
              font_weight = null;
            };
            comment = {
              color = terminal.brightBlack.normal.hex;
              font_style = null;
              font_weight = null;
            };
            keyword = {
              color = terminal.magenta.normal.hex;
              font_style = null;
              font_weight = null;
            };
            parameter = {
              color = terminal.blue.normal.hex;
              font_style = null;
              font_weight = null;
            };
            punctuation = {
              color = bootstrap.text.normal.hex;
              font_style = null;
              font_weight = null;
            };
            property = {
              color = terminal.cyan.normal.hex;
              font_style = null;
              font_weight = null;
            };
            function = {
              color = terminal.brightBlue.normal.hex;
              font_style = null;
              font_weight = null;
            };
            number = {
              color = terminal.red.normal.hex;
              font_style = null;
              font_weight = null;
            };
          };
        };
      }];
    };
  };
}


