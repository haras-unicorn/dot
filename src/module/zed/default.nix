{ pkgs, config, ... }:

let
  bootstrap = config.dot.colors.bootstrap;
  terminal = config.dot.colors.terminal;
in
{
  home.shared = {
    home.packages = [
      pkgs.zed-editor
    ];

    xdg.configFile."zed/settings.json".text =
      builtins.readFile ./settings.json;

    xdg.configFile."zed/themes/colors.json".text = builtins.toJSON {
      "$schema" = "https://zed.dev/schema/themes/v0.1.0.json";
      name = "colors";
      author = "haras";
      themes = [{
        name = "colors";
        appearance = if config.dot.colors.isLightTheme then "light" else "dark";
        style = {
          border = bootstrap.primary.normal;
          "border.variant" = bootstrap.secondary.normal;
          background = bootstrap.background.normal;
          "panel.background" = bootstrap.background.normal;
          "tab_bar.background" = bootstrap.background.normal;
          "tab.active_background" = bootstrap.background.normal;
          "tab.inactive_background" = bootstrap.background.alternate;
          "title_bar.background" = bootstrap.background.normal;
          "toolbar.background" = bootstrap.background.normal;
          "terminal.background" = bootstrap.background.normal;
          "surface.background" = bootstrap.background.normal;
          "scrollbar.track.border" = bootstrap.secondary.normal;
          "status_bar.background" = bootstrap.background.normal;
          "editor.active_line.background" = bootstrap.background.alternate;
          "editor.background" = bootstrap.background.normal;
          "editor.foreground" = bootstrap.text.normal;
          "editor.line_number" = bootstrap.text.alternate;
          "editor.gutter.background" = bootstrap.background.normal;
          "ghost_element.selected" = bootstrap.selection.normal;
          "ghost_element.background" = bootstrap.selection.alternate;
          "ghost_element.hover" = bootstrap.selection.normal;
          syntax = {
            constant = {
              color = terminal.yellow.normal;
              font_style = null;
              font_weight = null;
            };
            string = {
              color = terminal.green.normal;
              font_style = null;
              font_weight = null;
            };
            comment = {
              color = terminal.brightBlack.normal;
              font_style = null;
              font_weight = null;
            };
            keyword = {
              color = terminal.magenta.normal;
              font_style = null;
              font_weight = null;
            };
            parameter = {
              color = terminal.blue.normal;
              font_style = null;
              font_weight = null;
            };
            punctuation = {
              color = bootstrap.text.normal;
              font_style = null;
              font_weight = null;
            };
            property = {
              color = terminal.cyan.normal;
              font_style = null;
              font_weight = null;
            };
            function = {
              color = terminal.brightBlue.normal;
              font_style = null;
              font_weight = null;
            };
            number = {
              color = terminal.red.normal;
              font_style = null;
              font_weight = null;
            };
          };
        };
      }];
    };
  };
}
