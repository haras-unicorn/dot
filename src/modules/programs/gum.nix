{
  self.homeModules.gum.value =
    {
      lib,
      config,
      osConfig,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;
      colors = config.lib.stylix.colors.withHashtag;

      # NOTE: the nushell module evaluates each session variable as an
      # expression, and an unquoted hex color would start a comment
      nushellString = value: "'${value}'";

      accent = colors.cyan;
      highlight = colors.magenta;
      heading = colors.blue;
      muted = colors.base03;
      text = colors.base05;
      surface = colors.base01;
      onAccent = colors.base00;

      style = {
        GUM_INPUT_PROMPT_FOREGROUND = accent;
        GUM_INPUT_CURSOR_FOREGROUND = highlight;
        GUM_INPUT_PLACEHOLDER_FOREGROUND = muted;
        GUM_INPUT_HEADER_FOREGROUND = heading;

        GUM_CHOOSE_CURSOR_FOREGROUND = highlight;
        GUM_CHOOSE_SELECTED_FOREGROUND = accent;
        GUM_CHOOSE_HEADER_FOREGROUND = heading;

        GUM_FILE_CURSOR_FOREGROUND = highlight;
        GUM_FILE_SELECTED_FOREGROUND = accent;
        GUM_FILE_DIRECTORY_FOREGROUND = heading;
        GUM_FILE_SYMLINK_FOREGROUND = accent;
        GUM_FILE_PERMISSIONS_FOREGROUND = muted;
        GUM_FILE_FILE_SIZE_FOREGROUND = muted;
        GUM_FILE_HEADER_FOREGROUND = heading;

        GUM_FILTER_INDICATOR_FOREGROUND = highlight;
        GUM_FILTER_MATCH_FOREGROUND = accent;
        GUM_FILTER_PROMPT_FOREGROUND = accent;
        GUM_FILTER_PLACEHOLDER_FOREGROUND = muted;
        GUM_FILTER_HEADER_FOREGROUND = heading;

        GUM_CONFIRM_PROMPT_FOREGROUND = heading;
        GUM_CONFIRM_SELECTED_FOREGROUND = onAccent;
        GUM_CONFIRM_SELECTED_BACKGROUND = accent;
        GUM_CONFIRM_UNSELECTED_FOREGROUND = text;
        GUM_CONFIRM_UNSELECTED_BACKGROUND = surface;
      };
    in
    lib.mkIf hardware.editor {
      dot.programs.shell.sessionVariables = builtins.mapAttrs (_: nushellString) style;

      home.packages = [
        config.dot.programs.gum.package
      ];
    };
}
