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
          model = "openrouter/deepseek/deepseek-v4-flash-0731";
          small_model = "openrouter/deepseek/deepseek-v4-flash-0731";
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
          ${builtins.readFile ./AGENTS.md}

          ## References

          - `dot` flake URL: ${selfLib.source.url}
        '';

        themes.${theme}.theme.background = lib.mkForce "none";
      };
    };
}
