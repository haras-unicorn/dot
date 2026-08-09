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

      dataDir = "${config.home.homeDirectory}/.zeroclaw";
      agent = "main";
      agentWorkspaceDir = "${dataDir}/agents/${agent}/workspace";

      toml = pkgs.formats.toml { };

      configFile = toml.generate "zeroclaw-config.toml" {
        schema_version = 3;

        runtime.shell = lib.getExe pkgs.bash;

        providers.models.deepseek.main = {
          model = "deepseek-v4-flash";
          api_key = "$DEEPSEEK_API_KEY";
        };

        agents.${agent} = {
          model_provider = "deepseek.main";
          risk_profile = "main";
          runtime_profile = "main";
          channels = [ "matrix.main" ];
          mcp_bundles = [ "dev" ];
        };

        risk_profiles.main = {
          level = "supervised";
          workspace_only = true;
          allowed_commands = [ ];
          auto_approve = [
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
            "nixos__nix"
            "nixos__nix_versions"
            "web_search"
            "web_search_tool"
            "web_fetch"
            "cron_list"
            "cron_run"
            "cron_runs"
            "spawn_subagent"
            "delegate"
            "escalate_to_human"
            "calculator"
            "github__get_me"
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
          external_peers = [ "*" ];
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

        # NOTE: for now without embedding provider that requires llama.cpp most likely
        memory.search_mode = "bm25";
      };

      resolveConfig = pkgs.writeShellApplication {
        name = "zeroclaw-resolve-config";
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
    in
    {
      home.packages = [
        zeroclaw
      ];

      systemd.user.services.zeroclaw = {
        Unit = {
          Description = "ZeroClaw agent";
          After = [ "network-online.target" ];
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
          ExecStartPre = [ (lib.getExe resolveConfig) ];
          ExecStart = lib.getExe (
            pkgs.writeShellApplication {
              name = "zeroclaw-daemon";
              runtimeInputs = [
                zeroclaw
                pkgs.git
                pkgs.curl
              ];
              text = "zeroclaw daemon";
            }
          );
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
          ReadWritePaths = [ dataDir ];
        };
      };
    };
}
