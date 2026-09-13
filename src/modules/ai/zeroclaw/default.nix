{
  self,
  selfLib,
  lib,
  inputs,
  ...
}:

# NOTE: needed env vars:
# MATRIX_MORGAN_FETCH_HOMESERVER
# MATRIX_MORGAN_FETCH_USER_ID
# MATRIX_PEER
# MATRIX_DIGEST_ROOM
# MATRIX_HEARTBEAT_ROOM
# GIT_USER
# GIT_EMAIL
# GIT_SSH_KEY
# GITHUB_PERSONAL_ACCESS_TOKEN
# ZEROCLAW_providers__models__openrouter__main__api_key
# ZEROCLAW_channels__matrix__morgan_fetch__access_token
# ZEROCLAW_channels__matrix__morgan_fetch__recovery_key
# ZEROCLAW_channels__matrix__morgan_fetch__password

{
  machines.nixosModules.zeroclaw =
    {
      pkgs,
      config,
      ...
    }:
    let
      hardware = config.dot.hardware;

      system = pkgs.stdenv.hostPlatform.system;

      graphics = config.hardware.facter.detection.graphics;
      default = graphics.cards.default;
      hasNvidia = default.type == "nvidia";

      name = "zeroclaw";
      user = name;
      etcDir = "/etc/zeroclaw";
      envFile = "${etcDir}/.env";
      cacheDir = "/var/cache/${name}";
      dataDir = "/var/lib/${name}";
      chatAgent = "main";
      delegateAgent = "delegate";
      digestAgent = "digest";
      writerAgent = "writer";
      juniorDevAgent = "junior_dev";
      seniorDevAgent = "senior_dev";
      workspaceDir = "${dataDir}/workspace";
      sshDir = "${dataDir}/.ssh";
      planDb = "${dataDir}/plan.db";
      zeroclawConfigFile = "${dataDir}/config.toml";
      sopRunStateDir = "${dataDir}/sop";
      matrixChannelName = "morgan_fetch";
      matrixChannel = "matrix.morgan_fetch";

      gpuApi = config.dot.ai.apis.gpu;
      cpuApi = config.dot.ai.apis.cpu;
      embeddingApi = config.dot.ai.apis.embedding;

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

      gitSshCommand = pkgs.writeShellApplication {
        name = "git-ssh-command";
        runtimeInputs = [ pkgs.openssh ];
        text = ''
          mkdir -p "${sshDir}"
          ssh \
            -o "StrictHostKeyChecking=accept-new" \
            -o "UserKnownHostsFile=${sshDir}/known_hosts" \
            "$@"
        '';
      };

      gitMcpServerUnwrapped = pkgs.writeShellApplication {
        name = "git-mcp-server-unwrapped";
        runtimeInputs = [
          pkgs.openssh
          self.packages.${system}.git-mcp-server
        ];
        text = ''
          printf "%s" "$GIT_SSH_KEY" | sed 's/\\n/\n/g' | ssh-add -
          unset GIT_SSH_KEY
          git-mcp-server
        '';
      };

      gitMcpServer = pkgs.writeShellApplication {
        name = "git-mcp-server";
        runtimeInputs = [
          pkgs.openssh
          gitMcpServerUnwrapped
        ];
        text = "ssh-agent git-mcp-server-unwrapped";
      };

      toml = pkgs.formats.toml { };

      planConfig = toml.generate "plan-config.toml" {
        runtime = {
          tps_in = if gpuApi != null then gpuApi.tpsIn else 10000;
          tps_out = if gpuApi != null then gpuApi.tpsOut else 50;
          max_task_duration_secs = 600;
          queue_limit = 10;
          max_retries = 3;
        };
        sources = [
          {
            id = "chat";
            title = "Chat";
            description = "Tasks added via '${chatAgent}' agent.";
            type = "manual";
          }
          {
            id = "github";
            title = "GitHub";
            description = ''Run the `github` SOP with `sop_execute("github")`'';
            type = "poll";
          }
        ];
      };

      generalConfig = lib.recursiveUpdate selfLib.ai.zeroclaw.config {
        runtime.shell = lib.getExe pkgs.bash;

        web_fetch = {
          enabled = true;
          allowed_domains = selfLib.ai.web.allowedDomains;
        };

        web_search = {
          enabled = true;
        }
        // lib.optionalAttrs (config.dot.search.type == "searxng") {
          search_provider = "searxng";
          searxng_instance_url = config.dot.search.url;
        };

        cost = {
          enabled = true;
          daily_limit_usd = 2;
          monthly_limit_usd = 60;
          warn_at_percent = 80;
          enforcement.mode = "block";
          rates.tools.web_search.per_call = 0;
        };
      };

      mcpConfig = {
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
              env = {
                MCP_NIX_SANDBOX = builtins.concatStringsSep " " (
                  selfLib.ai.bubblewrap.flags.base
                  ++ [
                    "--bind"
                    "${workspaceDir}"
                    "${workspaceDir}"
                  ]
                  ++ lib.optionals hasNvidia selfLib.ai.bubblewrap.flags.nvidia
                );

              };
            }
            {
              name = "git";
              transport = "stdio";
              command = lib.getExe gitMcpServer;
              env = {
                MCP_TRANSPORT_TYPE = "stdio";
                MCP_LOG_LEVEL = "warn";
                GIT_SSH_COMMAND = lib.getExe gitSshCommand;
                GIT_BASE_DIR = "${workspaceDir}/projects";
              };
            }
            {
              name = "github";
              transport = "stdio";
              command = lib.getExe pkgs.github-mcp-server;
              args = [ "stdio" ];
              env = {
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
            {
              name = "rss";
              transport = "stdio";
              command = lib.getExe inputs.mcp-rss.packages.${system}.mcp-rss;
            }
            {
              name = "plan";
              transport = "stdio";
              command = lib.getExe pkgs.mcp-plan;
              args = [
                "--config"
                planConfig
                "run"
              ];
              env = {
                MCP_PLAN__DATABASE__URL = "sqlite://${planDb}";
              };
            }
          ];
        };

        mcp_bundles = {
          dev = {
            servers = [
              "nixos"
              "nix"
              "git"
              "github"
            ];
          };
          delegate = {
            servers = [
              "plan"
              "github"
            ];
          };
          digest = {
            servers = [
              "rss"
            ];
          };
          chat = {
            servers = [
              "rss"
              "plan"
            ];
          };
        };
      };

      channelConfig = {
        channels.matrix.${matrixChannelName} = {
          enabled = true;
          homeserver = "$MATRIX_MORGAN_FETCH_HOMESERVER";
          user_id = "$MATRIX_MORGAN_FETCH_USER_ID";
          allowed_rooms = [ ];
          reply_in_thread = false;
        };

        peer_groups.${matrixChannelName} = {
          channel = matrixChannel;
          agents = [
            delegateAgent
            chatAgent
          ];
          # NOTE: affects rooms as well
          external_peers = [ "$MATRIX_PEER" ];
        };
      };

      providerConfig = {
        memory =
          if embeddingApi != null then
            {
              search_mode = "hybrid";
              embedding_provider = "custom:${embeddingApi.url}";
              embedding_model = embeddingApi.model;
              embedding_dimensions = 1024;
            }
          else
            {
              search_mode = "bm25";
            };

        providers.models = {
          openrouter.main = {
            model = selfLib.ai.openrouter.profiles.default.model;
            timeout_secs = 5 * 60;
            provider_extra = selfLib.ai.openrouter.profiles.default.options;
          };
          custom =
            lib.optionalAttrs (gpuApi != null) {
              gpu = {
                native_tools = true;
                uri = gpuApi.url;
                timeout_secs = 10 * 60;
                model = gpuApi.model;
                fallback = [ "openrouter.main" ];
              };
            }
            // lib.optionalAttrs (cpuApi != null) {
              cpu = {
                native_tools = true;
                uri = cpuApi.url;
                timeout_secs = 30 * 60;
                model = cpuApi.model;
                fallback = [ "openrouter.main" ];
              };
            };
        };

        cost.rates = {
          providers.models = {
            openrouter.main = {
              input_per_mtok = selfLib.ai.openrouter.profiles.default.costInCents / 100.0;
              cached_input_per_mtok = selfLib.ai.openrouter.profiles.default.costCachedCents / 100.0;
              output_per_mtok = selfLib.ai.openrouter.profiles.default.costOutCents / 100.0;
            };

            custom =
              lib.optionalAttrs (gpuApi != null) {
                gpu = {
                  input_per_mtok = 0;
                  cached_input_per_mtok = 0;
                  output_per_mtok = 0;
                };
              }
              // lib.optionalAttrs (cpuApi != null) {
                cpu = {
                  input_per_mtok = 0;
                  cached_input_per_mtok = 0;
                  output_per_mtok = 0;
                };
              };
          };
        };
      };

      cronConfig = {
        cron = {
          digest = {
            job_type = "agent";
            schedule = {
              kind = "cron";
              expr = "0 6 * * *";
            };
            prompt = builtins.readFile ./cron/DIGEST.md;
            delivery = {
              mode = "announce";
              channel = matrixChannel;
              to = "$MATRIX_DIGEST_ROOM";
            };
          };
          heartbeat = {
            job_type = "agent";
            schedule = {
              kind = "cron";
              expr = "0 6 * * *";
            };
            prompt = builtins.readFile ./cron/HEARTBEAT.md;
            delivery = {
              mode = "announce";
              channel = matrixChannel;
              to = "$MATRIX_HEARTBEAT_ROOM";
            };
          };
        };
      };

      identityConfig = {
        format = "aieos";
        aieos_path = ./morgan-fetch.json;
      };

      workspaceConfig = {
        path = workspaceDir;
        read_memory_from = [
          chatAgent
          delegateAgent
          digestAgent
          writerAgent
          juniorDevAgent
          seniorDevAgent
        ];
      };

      chatAgentConfig = {
        agents.${chatAgent} = {
          identity = identityConfig;
          workspace = workspaceConfig;
          model_provider = "openrouter.main";
          risk_profile = chatAgent;
          runtime_profile = chatAgent;
          channels = [ matrixChannel ];
          mcp_bundles = [ "chat" ];
        };

        risk_profiles.${chatAgent} = selfLib.ai.zeroclaw.riskProfile // {
          excluded_tools = selfLib.ai.zeroclaw.tools.excludeExcept "chat";
          auto_approve = selfLib.ai.zeroclaw.tools.chat;
          allowed_commands = selfLib.ai.shell.allowedCommands;
        };

        runtime_profiles.${chatAgent} = selfLib.ai.zeroclaw.runtimeProfile // {
          max_context_tokens = selfLib.ai.openrouter.profiles.default.context;
        };
      };

      delegateAgentConfig = {
        agents.${delegateAgent} = {
          identity = identityConfig;
          workspace = workspaceConfig;
          model_provider = if gpuApi != null then "custom.gpu" else "openrouter.main";
          risk_profile = delegateAgent;
          runtime_profile = delegateAgent;
          channels = [ matrixChannel ];
          mcp_bundles = [ "delegate" ];
          cron_jobs = [ "heartbeat" ];
          delegates = [
            {
              agent = writerAgent;
              mode = "independent";
            }
            {
              agent = juniorDevAgent;
              mode = "independent";
            }
            {
              agent = seniorDevAgent;
              mode = "independent";
            }
          ];
        };

        risk_profiles.${delegateAgent} = selfLib.ai.zeroclaw.riskProfile // {
          excluded_tools = selfLib.ai.zeroclaw.tools.excludeExcept "delegate";
          auto_approve = selfLib.ai.zeroclaw.tools.delegate;
          allowed_commands = selfLib.ai.shell.allowedCommands;
          delegation_policy.mode = "allow";
        };

        runtime_profiles.${delegateAgent} = selfLib.ai.zeroclaw.runtimeProfile // {
          max_context_tokens =
            if gpuApi != null then gpuApi.context else selfLib.ai.openrouter.profiles.default.context;
          task_timeout_secs = 3 * 60 * 60;
        };
      };

      writerAgentConfig = {
        agents.${writerAgent} = {
          identity = identityConfig;
          workspace = workspaceConfig;
          model_provider = if gpuApi != null then "custom.gpu" else "openrouter.main";
          risk_profile = writerAgent;
          runtime_profile = writerAgent;
        };

        risk_profiles.${writerAgent} = selfLib.ai.zeroclaw.riskProfile // {
          excluded_tools = selfLib.ai.zeroclaw.tools.excludeExcept "writer";
          auto_approve = selfLib.ai.zeroclaw.tools.writer;
          allowed_commands = selfLib.ai.shell.allowedCommands;
        };

        runtime_profiles.${writerAgent} = selfLib.ai.zeroclaw.runtimeProfile // {
          agentic = true;
          max_context_tokens =
            if gpuApi != null then gpuApi.context else selfLib.ai.openrouter.profiles.default.context;
        };
      };

      juniorDevAgentConfig = {
        agents.${juniorDevAgent} = {
          identity = identityConfig;
          workspace = workspaceConfig;
          model_provider = if gpuApi != null then "custom.gpu" else "openrouter.main";
          risk_profile = juniorDevAgent;
          runtime_profile = juniorDevAgent;
          mcp_bundles = [ "dev" ];
        };

        risk_profiles.${juniorDevAgent} = selfLib.ai.zeroclaw.riskProfile // {
          excluded_tools = selfLib.ai.zeroclaw.tools.excludeExcept "dev";
          auto_approve = selfLib.ai.zeroclaw.tools.dev;
          allowed_commands = selfLib.ai.shell.allowedCommands;
        };

        runtime_profiles.${juniorDevAgent} = selfLib.ai.zeroclaw.runtimeProfile // {
          agentic = true;
          max_context_tokens =
            if gpuApi != null then gpuApi.context else selfLib.ai.openrouter.profiles.default.context;
        };
      };

      seniorDevAgentConfig = {
        agents.${seniorDevAgent} = {
          identity = identityConfig;
          workspace = workspaceConfig;
          model_provider = "openrouter.main";
          risk_profile = seniorDevAgent;
          runtime_profile = seniorDevAgent;
          mcp_bundles = [ "dev" ];
        };

        risk_profiles.${seniorDevAgent} = selfLib.ai.zeroclaw.riskProfile // {
          excluded_tools = selfLib.ai.zeroclaw.tools.excludeExcept "dev";
          auto_approve = selfLib.ai.zeroclaw.tools.dev;
          allowed_commands = selfLib.ai.shell.allowedCommands;
        };

        runtime_profiles.${seniorDevAgent} = selfLib.ai.zeroclaw.runtimeProfile // {
          agentic = true;
          max_context_tokens = selfLib.ai.openrouter.profiles.default.context;
        };
      };

      digestAgentConfig = {
        agents.${digestAgent} = {
          identity = identityConfig;
          workspace = workspaceConfig;
          model_provider = if cpuApi != null then "custom.cpu" else "openrouter.main";
          risk_profile = digestAgent;
          runtime_profile = digestAgent;
          mcp_bundles = [ "digest" ];
          cron_jobs = [ "digest" ];
        };

        risk_profiles.${digestAgent} = selfLib.ai.zeroclaw.riskProfile // {
          excluded_tools = selfLib.ai.zeroclaw.tools.excludeExcept "digest";
          auto_approve = selfLib.ai.zeroclaw.tools.digest;
          allowed_commands = selfLib.ai.shell.allowedCommands;
        };

        runtime_profiles.${digestAgent} = selfLib.ai.zeroclaw.runtimeProfile // {
          agentic = true;
          max_context_tokens =
            if cpuApi != null then cpuApi.context else selfLib.ai.openrouter.profiles.default.context;
        };
      };

      zeroclawConfig = toml.generate "${name}-config.toml" (
        builtins.foldl' lib.recursiveUpdate { } [
          generalConfig
          mcpConfig
          channelConfig
          providerConfig
          cronConfig
          chatAgentConfig
          delegateAgentConfig
          writerAgentConfig
          juniorDevAgentConfig
          seniorDevAgentConfig
          digestAgentConfig
        ]
      );
    in
    lib.mkIf hardware.network {
      nixpkgs.overlays = [
        inputs.mcp-nix.overlays.default
        inputs.mcp-plan.overlays.default
      ];

      environment.systemPackages = [
        zeroclawCli
      ];

      users.groups.${user} = { };
      users.users.${user} = {
        group = user;
        isSystemUser = true;
        home = dataDir;
        extraGroups = lib.mkIf hasNvidia [ "video" ];
      };

      nix.settings.allowed-users = [ user ];

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
          mkdir -p "${dataDir}"
          envsubst < "${zeroclawConfig}" > "${dataDir}/.zeroclaw.config.toml.tmp"
          chmod 0600 "${dataDir}/.zeroclaw.config.toml.tmp"
          mv -f "${dataDir}/.zeroclaw.config.toml.tmp" "${zeroclawConfigFile}"
        '';
        script = ''
          zeroclaw daemon
        '';
        serviceConfig = {
          EnvironmentFile = envFile;
          WorkingDirectory = dataDir;
          StateDirectory = builtins.baseNameOf dataDir;
          CacheDirectory = builtins.baseNameOf cacheDir;
          User = user;
          Group = user;
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
          ProtectHome = true;
          ProtectClock = true;
          PrivateDevices = !hasNvidia;
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
          pkgs.systemd
          pkgs.jq
        ];
        script = ''
          tail -n0 -F "${dataDir}/data/state/runtime-trace.jsonl" \
            | jq \
            | systemd-cat -t zeroclaw-trace
        '';
      };
    };

  machines.homeModules.zeroclaw =
    { osConfig, ... }:
    let
      hardware = osConfig.dot.hardware;

      gateway = selfLib.ai.zeroclaw.config.gateway;

      zeroclawWeb = osConfig.dot.programs.chromium.launch {
        name = "zeroclaw";
        address = "http://${gateway.host}:${builtins.toString gateway.port}";
      };
    in
    {
      xdg.desktopEntries.zeroclaw = lib.mkIf hardware.browser {
        name = "ZeroClaw";
        exec = lib.getExe zeroclawWeb;
        terminal = false;
      };
    };
}
