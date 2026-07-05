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
    in
    lib.mkIf hardware.editor {
      home.sessionVariables = {
        OPENCODE_DISABLE_LSP_DOWNLOAD = true;
      };

      programs.opencode = {
        enable = true;
        settings = {
          autoupdate = false;
          share = "disabled";
          compaction.prune = true;
          provider.openrouter.models = {
            "deepseek/deepseek-v4-pro".options.provider.only = [ "deepseek" ];
            "deepseek/deepseek-v4-flash".options.provider.only = [ "deepseek" ];
          };
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
          - the `tree` command (available via PATH): ${lib.getExe config.dot.programs.shell.tree}
          - the `list` command (available via PATH): ${lib.getExe config.dot.programs.shell.list}
        '';
      };
    };
}
