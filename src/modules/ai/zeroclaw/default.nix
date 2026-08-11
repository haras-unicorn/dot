{ inputs, lib, ... }:

{
  machines.homeModules.zeroclaw =
    {
      pkgs,
      config,
      ...
    }:
    let
      system = pkgs.stdenv.hostPlatform.system;

      zeroclaw = (inputs.llm-agents.packages.${system}.zeroclaw).overrideAttrs (old: {
        cargoBuildFlags = (old.cargoBuildFlags or [ ]) ++ [
          "--features"
          "channel-matrix"
        ];
      });

      nixCache = "${config.xdg.cacheHome}/nix";
      nixState = "${config.xdg.stateHome}/nix";

      dataDir = "${config.home.homeDirectory}/.zeroclaw";
      agent = "main";
      agentWorkspaceDir = "${dataDir}/agents/${agent}/workspace";

      toml = pkgs.formats.toml { };

      generalConfig = {
        agents.${agent} = {
          risk_profile = "main";
          runtime_profile = "main";
          channels = [ "matrix.main" ];
          mcp_bundles = [ "dev" ];
        };

        schema_version = 3;

        runtime.shell = lib.getExe pkgs.bash;

        knowledge.enabled = true;

        verifiable_intent.enabled = true;

        link_enricher.enabled = true;

        project_intel.enabled = true;

        web_fetch = {
          enabled = true;
          allowed_domains = [
            "en.wikipedia.org"
            "wiki.archlinux.org"
            "docs.zeroclawlabs.ai"
            "nixos.org"
            "nix.dev"
            "docs.rs"
            "developer.mozilla.org"
            "huggingface.co"
          ];
        };

        risk_profiles.main = {
          level = "supervised";
          workspace_only = true;
          sandbox_backend = "bwrap";
          sandbox_enabled = true;

          tool_receipts = {
            enabled = true;
            show_in_response = true;
          };

          allowed_commands = [
            "ls"
            "pwd"
            "tree"
            "stat"
            "file"
            "readlink"
            "du"
            "df"
            "cat"
            "head"
            "tail"
            "wc"
            "sed"
            "jq"
            "grep"
            "rg"
            "find"
            "fd"
            "env"
            "whoami"
            "id"
            "date"
            "uname"
            "uptime"
            "ps"
            "free"
            "echo"
            "printf"
            "sha256sum"
            "sleep"
            "true"
            "false"

            "nix"
            "git"
          ];

          excluded_tools = [
            "browser"
            "schedule"
            "screenshot"
            "browser_open"
            "proxy_config"
            "model_switch"
            "model_routing_config"
            "memory_export"
            "memory_purge"
          ];

          auto_approve = [
            # NOTE: it looks scary but it gets parsed
            # and denied when certain metacharacters get used and such
            # more discussion is needed but as things stand it looks
            # safe to use with a list of allowed commands
            "shell"
            "sessions_current"
            "sessions_history"
            "sessions_list"
            "knowledge"
            "file_read"
            "file_write"
            "file_edit"
            "glob_search"
            "content_search"
            "git_operations"
            "git_forge"
            "memory_recall"
            "memory_store"
            "memory_forget"
            "memory_export"
            "web_search"
            "web_search_tool"
            "web_fetch"
            "cron_list"
            "cron_run"
            "cron_runs"
            "spawn_subagent"
            "delegate"
            "escalate_to_human"
            "ask_user"
            "calculator"
            "reaction"
            "send_message_to_peer"
            "sessions_send"
            "project_intel"

            "nixos__nix"
            "nixos__nix_versions"

            "github__get_me"
            "github__search_commits"
            "github__search_repositories"
            "github__search_users"
            "github__get_file_contents"
            "github__get_repository_tree"
            "github__list_commits"
            "github__get_commit"
            "github__list_branches"
            "github__search_code"
            "github__fork_repository"
            "github__create_repository"
            "github__create_branch"
            "github__create_or_update_file"
            "github__push_files"
            "github__delete_file"
            "github__list_repository_collaborators"
            "github__issue_read"
            "github__issue_write"
            "github__list_issues"
            "github__search_issues"
            "github__add_issue_comment"
            "github__list_issue_types"
            "github__pull_request_read"
            "github__list_pull_requests"
            "github__search_pull_requests"
            "github__create_pull_request"
            "github__update_pull_request"
            "github__merge_pull_request"
            "github__update_pull_request_branch"
          ];
        };

        runtime_profiles.main = {
          max_tool_iterations = 100;
          max_actions_per_hour = 1000;
        };

        channels.matrix.main = {
          enabled = true;
          homeserver = "$MATRIX_HOMESERVER";
          user_id = "$MATRIX_USER_ID";
          password = "$MATRIX_PASSWORD";
          recovery_key = "$MATRIX_RECOVERY_KEY";
          allowed_rooms = [ ];
          reply_in_thread = false;
        };

        peer_groups.main = {
          channel = "matrix.main";
          agents = [ "main" ];
          # NOTE: affects rooms as well
          external_peers = [ "$MATRIX_PEER" ];
        };

        mcp = {
          enabled = true;
          servers = [
            {
              name = "github";
              transport = "stdio";
              command = lib.getExe pkgs.github-mcp-server;
              args = [
                "stdio"
              ];
              env = {
                GITHUB_PERSONAL_ACCESS_TOKEN = "$GITHUB_PERSONAL_ACCESS_TOKEN";
              };
            }
            {
              name = "nixos";
              transport = "stdio";
              command = lib.getExe pkgs.mcp-nixos;
              args = [ ];
            }
          ];
        };

        mcp_bundles.dev = {
          servers = [
            "github"
            "nixos"
          ];
        };

        web_search = {
          enabled = true;
          search_provider = "duckduckgo";
        };

        memory = {
          search_mode = "hybrid";
          embedding_provider = "custom:http://127.0.0.1:8081/v1";
          embedding_model = "qwen-3-embedding";
          embedding_dimensions = 1024;
        };
      };

      deepseekConfig = {
        providers.models.deepseek.main = {
          model = "deepseek-v4-flash";
          api_key = "$DEEPSEEK_API_KEY";
        };

        agents.${agent} = {
          model_provider = "deepseek.main";
        };
      };

      # TODO: use when moe gpu compute gets fixed
      # llamaConfig = {
      #   providers.models.llamacpp.main = {
      #     model = "qwen-3-6-35b-a3b";
      #     timeout_secs = 600;
      #     vision = false;
      #     fallback = [ "deepseek.main" ];
      #   };

      #   providers.models.llamacpp.small = {
      #     model = "qwen-3-5-4b";
      #     timeout_secs = 300;
      #     vision = false;
      #     fallback = [ "deepseek.main" ];
      #   };

      #   agents.${agent} = {
      #     model_provider = "llamacpp.main";
      #     delegates = [
      #       {
      #         agent = "small";
      #         mode = "bounded";
      #       }
      #       {
      #         agent = "reasoner";
      #         mode = "bounded";
      #       }
      #     ];
      #   };

      #   # NOTE: delegate-only agents — no channels, reached via the delegate
      #   # tool from agents.main.
      #   # Workspace is space as agent that spawns them (main).
      #   agents.small = {
      #     model_provider = "llamacpp.small";
      #     risk_profile = "main";
      #     runtime_profile = "main";
      #   };

      #   agents.reasoner = {
      #     model_provider = "deepseek.main";
      #     risk_profile = "main";
      #     runtime_profile = "main";
      #   };
      # };

      configFile = toml.generate "zeroclaw-config.toml" (
        lib.recursiveUpdate deepseekConfig generalConfig
      );

      preStart = pkgs.writeShellApplication {
        name = "zeroclaw-pre-start";
        runtimeInputs = [
          pkgs.envsubst
        ];
        text = ''
          mkdir -p ${dataDir}
          envsubst < ${configFile} > ${dataDir}/.config.toml.tmp
          chmod 0600 ${dataDir}/.config.toml.tmp
          mv -f ${dataDir}/.config.toml.tmp ${dataDir}/config.toml

          mkdir -p ${agentWorkspaceDir}
          install -m 0644 ${./AGENTS.md} "${agentWorkspaceDir}/AGENTS.md"
          install -m 0644 ${./IDENTITY.md} "${agentWorkspaceDir}/IDENTITY.md"
          install -m 0644 ${./SOUL.md} "${agentWorkspaceDir}/SOUL.md"
          install -m 0644 ${./TOOLS.md} "${agentWorkspaceDir}/TOOLS.md"
          install -m 0644 ${./USER.md} "${agentWorkspaceDir}/USER.md"
        '';
      };

      start = pkgs.writeShellApplication {
        name = "zeroclaw-start";
        runtimeInputs = [
          zeroclaw

          pkgs.git
          pkgs.curl
          pkgs.bubblewrap

          pkgs.coreutils
          pkgs.procps
          pkgs.gnused
          pkgs.gnugrep
          pkgs.findutils
          pkgs.ripgrep
          pkgs.fd
          pkgs.tree
          pkgs.file
          pkgs.jq

          pkgs.git
          pkgs.nix
        ];
        text = "zeroclaw daemon";
      };

      trace = pkgs.writeShellApplication {
        name = "zeroclaw-trace-bridge";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.systemd
        ];
        text = ''
          tail -n0 -F "${dataDir}/data/state/runtime-trace.jsonl" \
            | systemd-cat -t zeroclaw-jsonl
        '';
      };
    in
    {
      home.packages = [
        zeroclaw
      ];

      systemd.user.services.zeroclaw = {
        Unit = {
          Description = "ZeroClaw agent";
        };

        Install = {
          WantedBy = [ "default.target" ];
        };

        Service = {
          Type = "simple";
          WorkingDirectory = dataDir;
          EnvironmentFile = "-${dataDir}/.env";
          Environment = [
            "ZEROCLAW_CONFIG_DIR=${dataDir}"
            "ZEROCLAW_WORKSPACE=${dataDir}/workspace"
          ];
          ExecStartPre = [ (lib.getExe preStart) ];
          ExecStart = lib.getExe start;
          Restart = "on-failure";
          RestartSec = "5s";

          NoNewPrivileges = true;
          PrivateTmp = true;
          PrivateDevices = true;
          ProtectSystem = "strict";
          ProtectHome = "read-only";
          ProtectClock = true;
          ProtectHostname = true;
          MemoryDenyWriteExecute = true;
          RemoveIPC = true;
          RestrictNamespaces = true;
          RestrictRealtime = true;
          RestrictSUIDSGID = true;
          RestrictAddressFamilies = [
            "AF_INET"
            "AF_INET6"
            "AF_UNIX"
          ];
          LockPersonality = true;
          SystemCallArchitectures = "native";
          CapabilityBoundingSet = [ "" ];
          AmbientCapabilities = [ "" ];
          SystemCallFilter = [
            "@system-service"
            "~@privileged"
            "~@resources"
          ];
          UMask = "0077";
          ReadWritePaths = [
            dataDir
            nixCache
            nixState
          ];
        };
      };

      systemd.user.services.zeroclaw-trace = {
        Unit.Description = "Tail ZeroClaw JSONL trace into journal";
        Install.WantedBy = [ "default.target" ];
        Service = {
          ExecStart = lib.getExe trace;
          Restart = "always";
        };
      };
    };
}
