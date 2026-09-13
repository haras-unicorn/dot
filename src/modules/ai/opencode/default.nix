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

      opencode = pkgs.writeShellApplication {
        name = "opencode";
        runtimeInputs = [
          pkgs.opencode
          pkgs.libuuid
        ];
        text = ''
          OPENCODE__PROVIDER__OPENROUTER__OPTIONS__SESSION_ID="$(uuidgen)"
          export OPENCODE__PROVIDER__OPENROUTER__OPTIONS__SESSION_ID
          opencode "$@"
        '';
      };
    in
    lib.mkIf hardware.editor {
      home.sessionVariables = {
        OPENCODE_DISABLE_LSP_DOWNLOAD = true;
      };

      programs.opencode = {
        enable = true;

        package = opencode;

        tui = {
          theme = theme;
          scroll_acceleration = true;
        };

        settings = {
          autoupdate = false;
          share = "disabled";
          compaction.prune = true;
          provider.openrouter.options = selfLib.openrouter.profiles.dev.options // {
            session_id = "{env:OPENCODE__PROVIDER__OPENROUTER__OPTIONS__SESSION_ID}";
          };
          enabled_providers = [ "openrouter" ];
          model = selfLib.openrouter.profiles.dev.model;
          small_model = selfLib.openrouter.profiles.dev.model;
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
