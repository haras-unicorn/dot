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

      opencodeLocal = pkgs.writeShellApplication {
        name = "opencode-local";
        runtimeInputs = [
          pkgs.harasPackages.opencode
          pkgs.systemd
        ];
        text = ''
          set -euo pipefail

          service="omw.service"
          model="${osConfig.corm.gpu-provider.model.passthru.modelName}"

          cleanup() {
            sudo systemctl start "$service" >/dev/null 2>&1 || true
          }
          trap cleanup EXIT INT TERM

          sudo systemctl stop "$service"

          has_model=false
          for arg in "$@"; do
            case "$arg" in
              --model | --model=*) has_model=true ;;
            esac
          done
          if [ "$has_model" = false ]; then
            set -- --model "corm/$model" "$@"
          fi

          opencode "$@"
        '';
      };
    in
    lib.mkIf hardware.editor {
      home.sessionVariables = {
        OPENCODE_DISABLE_LSP_DOWNLOAD = true;
      };

      home.packages = lib.optionals hardware.cuda [ opencodeLocal ];

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
          }
          // lib.optionalAttrs hardware.cuda {
            corm = {
              npm = "@ai-sdk/openai-compatible";
              name = "Corm GPU";
              options = {
                baseURL = "http://${osConfig.corm.gpu-provider.host}:${builtins.toString osConfig.corm.gpu-provider.port}/v1";
                apiKey = "corm";
              };
              models = {
                "${osConfig.corm.gpu-provider.model.passthru.modelName}" = {
                  name = osConfig.corm.gpu-provider.model.passthru.modelName;
                  limit = {
                    context = osConfig.corm.gpu-provider.ctx;
                    output = 8192;
                  };
                };
              };
            };
          };
          enabled_providers = [ "openrouter" ] ++ lib.optionals hardware.cuda [ "corm" ];
          model = selfLib.openrouter.profiles.dev.model;
          small_model = selfLib.openrouter.profiles.dev.model;
          lsp = true;
          permission = {
            webfetch = "allow";
            websearch = "allow";
          };
          tools = {
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
