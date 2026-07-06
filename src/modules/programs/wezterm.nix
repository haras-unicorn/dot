{
  machines.homeModules.wezterm =
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

      shell = config.dot.programs.shell;

      vars = lib.generators.toLua { multiline = false; } cfg.sessionVariables;
    in
    lib.mkIf hardware.visual {
      dot.programs.terminal.package = config.programs.wezterm.package;

      programs.wezterm.enable = true;
      # NOTE: https://github.com/nix-community/stylix/blob/release-26.05/modules/wezterm/hm.nix
      # stylix overrides home-manager settings so we need to write it like this in 26.05...
      stylix.targets.wezterm.luaBody = ''
        default_cursor_style = "SteadyBar",
        audible_bell = "Disabled",
        default_prog = { "${lib.getExe shell.package}" },
        set_environment_variables = ${vars},
        enable_tab_bar = false,
        window_padding = {
          left = 0,
          right = 0,
          top = 0,
          bottom = 0,
        },
      '';
    };
}
