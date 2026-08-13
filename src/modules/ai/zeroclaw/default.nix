{
  self,
  lib,
  inputs,
  ...
}:

{
  machines.nixosModules.zeroclaw =
    {
      pkgs,
      config,
      ...
    }:
    let
      system = pkgs.stdenv.hostPlatform.system;

      name = "zeroclaw";
      user = name;
      cacheDir = "/var/cache/${name}";
      dataDir = "/var/lib/${name}";
      agent = "main";
      agentWorkspaceDir = "${dataDir}/agents/${agent}/workspace";
      sshDir = "${dataDir}/.ssh";

      zeroclaw = self.packages.${system}.zeroclaw;
      zeroclawCli = pkgs.writeShellApplication {
        name = "zeroclaw";
        runtimeInputs = [ zeroclaw ];
        text = ''
          /run/wrappers/bin/sudo \
            -u "${user}" \
            ZEROCLAW_CONFIG_DIR="${dataDir}" \
            zeroclaw "$@"
        '';
      };

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

          sandbox_backend = "bubblewrap";
          sandbox_enabled = true;

          tool_receipts = {
            enabled = true;
            show_in_response = true;
          };

          allowed_commands = [
            "ls"
            "mkdir"
            "cp"
            "mv"
            "rm"
            "touch"
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

          # NOTE: shell is ok because sandboxing and zeroclaw also parses it to check for
          # allowed commands and disallows certain metacharacters
          auto_approve = [
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
            "weather"
            "TodoWrite"

            "nixos__nix"
            "nixos__nix_versions"

            "nix__nix_build"
            "nix__nix_run"
            "nix__nix_develop"
            "nix__nix_check"

            "git__git_init"
            "git__git_clone"
            "git__git_status"
            "git__git_clean"
            "git__git_add"
            "git__git_commit"
            "git__git_diff"
            "git__git_log"
            "git__git_show"
            "git__git_blame"
            "git__git_reflog"
            "git__git_changelog_analyze"
            "git__git_branch"
            "git__git_checkout"
            "git__git_merge"
            "git__git_rebase"
            "git__git_cherry_pick"
            "git__git_remote"
            "git__git_fetch"
            "git__git_pull"
            "git__git_push"
            "git__git_tag"
            "git__git_stash"
            "git__git_reset"
            "git__git_worktree"
            "git__git_set_working_dir"
            "git__git_clear_working_dir"

            "github__actions_get"
            "github__actions_list"
            "github__get_job_logs"
            "github__get_me"
            "github__get_team_members"
            "github__get_teams"
            "github__discussion_comment_write"
            "github__get_discussion"
            "github__get_discussion_comments"
            "github__list_discussion_categories"
            "github__list_discussions"
            "github__add_issue_comment"
            "github__get_label"
            "github__issue_read"
            "github__issue_write"
            "github__list_issue_fields"
            "github__list_issue_types"
            "github__search_issues"
            "github__sub_issue_write"
            "github__get_label"
            "github__label_write"
            "github__list_label"
            "github__dismiss_notification"
            "github__get_notification_details"
            "github__list_notifications"
            "github__manage_notification_subscription"
            "github__manage_repository_notification_subscription"
            "github__mark_all_notifications_read"
            "github__projects_get"
            "github__projects_list"
            "github__projects_write"
            "github__add_comment_to_pending_review"
            "github__add_reply_to_pull_request_comment"
            "github__create_pull_request"
            "github__list_pull_requests"
            "github__merge_pull_request"
            "github__pull_request_read"
            "github__pull_request_review_write"
            "github__search_pull_requests"
            "github__update_pull_request"
            "github__update_pull_request_branch"
            "github__create_branch"
            "github__create_repository"
            "github__fork_repository"
            "github__get_commit"
            "github__get_file_contents"
            "github__get_latest_release"
            "github__get_release_by_tag"
            "github__get_tag"
            "github__list_branches"
            "github__list_commits"
            "github__list_releases"
            "github__list_repository_collaborators"
            "github__list_tags"
            "github__search_code"
            "github__search_commits"
            "github__search_repositories"
            "github__list_starred_repositories"
            "github__star_repository"
            "github__unstar_repository"
            "github__search_users"
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
              name = "nixos";
              transport = "stdio";
              command = lib.getExe pkgs.mcp-nixos;
            }
            {
              name = "nix";
              transport = "stdio";
              command = lib.getExe pkgs.mcp-nix;
            }
            {
              name = "git";
              transport = "stdio";
              command = lib.getExe self.packages.${system}.git-mcp-server;
              env = {
                MCP_TRANSPORT_TYPE = "stdio";
                MCP_LOG_LEVEL = "warn";
                GIT_SSH_COMMAND =
                  "echo \"$GIT_SSH_KEY\""
                  + " | ssh -i /dev/stdin"
                  + " -o IdentitiesOnly=yes"
                  + " -o StrictHostKeyChecking=accept-new"
                  + " -o UserKnownHostsFile=${sshDir}/known_hosts";
                GIT_USER = "$GIT_USER";
                GIT_EMAIL = "$GIT_EMAIL";
              };
            }
            {
              name = "github";
              transport = "stdio";
              command = lib.getExe pkgs.github-mcp-server;
              args = [ "stdio" ];
              env = {
                GITHUB_PERSONAL_ACCESS_TOKEN = "$GITHUB_PERSONAL_ACCESS_TOKEN";
                GITHUB_TOOLSETS = builtins.concatStringsSep "," [
                  "context"
                  "repos"
                  "issues"
                  "labels"
                  "notifications"
                  "discussions"
                  "projects"
                  "stargazers"
                  "actions"
                  "pull_requests"
                  "users"
                ];
              };
            }
          ];
        };

        mcp_bundles.dev = {
          servers = [
            "nixos"
            "nix"
            "git"
            "github"
          ];
        };

        web_search = {
          enabled = true;
          search_provider = "duckduckgo";
        };

        memory.search_mode = "bm25";
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
      #
      #   memory = {
      #     search_mode = "hybrid";
      #     embedding_provider = "custom:http://127.0.0.1:8081/v1";
      #     embedding_model = "qwen-3-embedding";
      #     embedding_dimensions = 1024;
      #   };
      # };

      configFile = toml.generate "${name}-config.toml" (lib.recursiveUpdate deepseekConfig generalConfig);
    in
    {
      nixpkgs.overlays = [
        inputs.mcp-nix.overlays.default
      ];

      environment.systemPackages = [
        zeroclawCli
      ];

      users.groups.${user} = { };
      users.users.${user} = {
        group = user;
        isSystemUser = true;
        home = dataDir;
      };

      nix.settings.allowed-users = [ user ];

      systemd.tmpfiles.rules = [
        "d ${sshDir} 0700 ${user} ${user} -"
      ];

      systemd.services.${name} = {
        wantedBy = [ "multi-user.target" ];
        requires = [ "network-online.target" ];
        after = [ "network-online.target" ];
        path = [
          pkgs.envsubst

          zeroclaw

          # NOTE: needed for runtime
          pkgs.git
          pkgs.curl
          pkgs.bubblewrap

          # NOTE: agent commands
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
        ];
        preStart = ''
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
        script = ''
          zeroclaw daemon
        '';
        serviceConfig = {
          WorkingDirectory = dataDir;
          StateDirectory = builtins.baseNameOf dataDir;
          CacheDirectory = builtins.baseNameOf cacheDir;
          User = user;
          Group = user;
          EnvironmentFile = "-${dataDir}/.env";
          Environment = [
            "ZEROCLAW_CONFIG_DIR=${dataDir}"
            # NOTE: for nix client
            "XDG_STATE_HOME=${dataDir}"
            "XDG_CACHE_HOME=${cacheDir}"
          ];
          Restart = "on-failure";
          RestartSec = "5s";
          UMask = "0077";

          # NOTE: be very careful how you harden here
          # because of bwrap
          # NOTE: zeroclaw uses this bwrap --ro-bind /usr /usr --ro-bind /usr/local /usr/local --ro-bind /bin /bin --ro-bind /sbin /sbin --ro-bind /nix/store /nix/store --dev /dev --proc /proc --bind /tmp /tmp --unshare-all --die-with-parent --cap-drop CAP_SYS_ADMIN --cap-drop CAP_SYS_PTRACE
          ProtectHome = true;
          ProtectClock = true;
          PrivateDevices = true;
          NoNewPrivileges = true;
          ProtectSystem = "strict";
          MemoryDenyWriteExecute = true;
          RemoveIPC = true;
          RestrictSUIDSGID = true;
          RestrictAddressFamilies = [
            "AF_INET"
            "AF_INET6"
            "AF_UNIX"
            "AF_NETLINK"
          ];
          LockPersonality = true;
          SystemCallArchitectures = "native";
          CapabilityBoundingSet = [ "" ];
          AmbientCapabilities = [ "" ];
          ProtectControlGroups = true;
          ProtectKernelModules = true;
          RestrictRealtime = true;
          ProtectProc = "invisible";
          PrivateIPC = true;
        };
      };

      systemd.services.zeroclaw-trace = {
        wantedBy = [ "multi-user.target" ];
        requires = [
          "network-online.target"
          "zeroclaw.service"
        ];
        after = [
          "network-online.target"
          "zeroclaw.service"
        ];
        path = [
          pkgs.coreutils
          pkgs.systemd
        ];
        script = ''
          tail -n0 -F "${dataDir}/data/state/runtime-trace.jsonl" \
            | systemd-cat -t zeroclaw-trace
        '';
      };
    };
}
