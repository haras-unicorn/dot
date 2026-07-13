{ selfLib, ... }:

{
  machines.homeModules.opencode =
    {
      pkgs,
      lib,
      osConfig,
      config,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;

      theme = "stylix";
    in
    lib.mkIf hardware.editor {
      home.sessionVariables = {
        OPENCODE_DISABLE_LSP_DOWNLOAD = true;
      };

      programs.opencode = {
        enable = true;

        tui = {
          theme = theme;
          scroll_acceleration = true;
        };
        settings = {
          autoupdate = false;
          share = "disabled";
          compaction.prune = true;
          enabled_providers = [ "deepseek" ];
          model = "deepseek/deepseek-v4-pro";
          small_model = "deepseek/deepseek-v4-flash";
          lsp = true;
          permission = {
            bash = {
              "*" = "deny";
              "dev *" = "allow";
              "just *" = "allow";
              "make *" = "allow";
            };
            external_directory = {
              "*" = "deny";
              "${config.home.homeDirectory}" = "ask";
            };
          };
        };
        context = ''
          ${builtins.readFile ./context.md}

          ## References

          - `dot` flake URL: ${selfLib.source.url}
          - the `tree` command (available via PATH): ${lib.getExe config.dot.commands.tree}
          - the `list` command (available via PATH): ${lib.getExe config.dot.commands.list}
        '';

        themes.${theme}.theme.background = lib.mkForce "none";
      };
    };
}
