{ selfLib, ... }:

{
  self.homeModules.opencode.value =
    {
      pkgs,
      lib,
      osConfig,
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

        package = pkgs.harasPackages.opencode;

        enableMcpIntegration = true;

        skills = selfLib.ai.skills;

        tui = {
          theme = theme;
          scroll_acceleration = true;
        };

        settings = {
          autoupdate = false;
          share = "disabled";
          compaction.prune = true;
          provider = {
            openrouter.options = selfLib.openrouter.profiles.dev.options // {
              session_id = "{env:OPENCODE__PROVIDER__OPENROUTER__OPTIONS__SESSION_ID}";
            };
          };
          enabled_providers = [ "openrouter" ];
          model = selfLib.openrouter.profiles.dev.model;
          small_model = selfLib.openrouter.profiles.dev.model;
          lsp = true;
          permission = {
            websearch = "allow";
          };
          tools = {
            # NOTE: the web MCP's `web_fetch` replaces the built-in one
            webfetch = false;
            web_web_search = false;
            question = false;
            bash = false;
            shell = false;
            read = false;
            glob = false;
            grep = false;
            list = false;
            edit = false;
            write = false;
            patch = false;
            apply_patch = false;
            task = false;
            task_status = false;
            todo = false;
            todowrite = false;
            repo_clone = false;
            repo_overview = false;
            lsp = false;
            plan = false;
            git_git_push = false;
            git_git_tag = false;
            git_git_remote = false;
          };
        };

        context = selfLib.ai.agents;

        themes.${theme}.theme.background = lib.mkForce "none";
      };
    };
}
