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
      juniorDevAgent = "junior_dev";
      seniorDevAgent = "senior_dev";
      workspaceDir = "${dataDir}/workspace";
      sshDir = "${dataDir}/.ssh";

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

      generalConfig = lib.recursiveUpdate selfLib.ai.zeroclaw.config {
        runtime.shell = lib.getExe pkgs.bash;

        web_fetch = {
          enabled = true;
          allowed_domains = selfLib.ai.web.allowedDomains;
        };

        web_search = {
          enabled = true;
          search_provider =
            if config.dot.search.type == "searxng" then
              "searxng"
            else
              builtins.throw "Unsupported search type ${config.dot.search.type}";
        }
        // lib.optionalAttrs (config.dot.search.type == "searxng") {
          searxng_instance_url = config.dot.search.url;
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
          digest = {
            servers = [
              "rss"
            ];
          };
        };
      };

      channelConfig = {
        channels.matrix.morgan_fetch = {
          enabled = true;
          homeserver = "$MATRIX_MORGAN_FETCH_HOMESERVER";
          user_id = "$MATRIX_MORGAN_FETCH_USER_ID";
          allowed_rooms = [ ];
          reply_in_thread = false;
        };

        peer_groups.morgan_fetch = {
          channel = "matrix.morgan_fetch";
          agents = [ delegateAgent ];
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
            model = selfLib.ai.openrouter.model;
            provider_extra = selfLib.ai.openrouter.options;
          };
          custom =
            lib.optionalAttrs (gpuApi != null) {
              gpu = {
                uri = gpuApi.url;
                timeout_secs = 300;
                model = gpuApi.model;
                fallback = [ "openrouter.main" ];
              };
            }
            // lib.optionalAttrs (cpuApi != null) {
              cpu = {
                uri = cpuApi.url;
                timeout_secs = 300;
                model = cpuApi.model;
                fallback = [ "openrouter.main" ];
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
              channel = "matrix.morgan_fetch";
              to = "$MATRIX_DIGEST_ROOM";
            };
          };
        };
      };

      workspaceConfig = {
        path = workspaceDir;
        read_memory_from = [
          chatAgent
          delegateAgent
          digestAgent
          juniorDevAgent
          seniorDevAgent
        ];
      };

      chatAgentConfig = {
        agents.${chatAgent} = {
          workspace = workspaceConfig;
          model_provider = "openrouter.main";
          risk_profile = chatAgent;
          runtime_profile = chatAgent;
          channels = [ "matrix.morgan_fetch" ];
        };

        risk_profiles.${chatAgent} = selfLib.ai.zeroclaw.riskProfile // {
          excluded_tools = selfLib.ai.zeroclaw.excludedTools;
          allowed_tools = selfLib.ai.zeroclaw.chatTools;
          auto_approve = selfLib.ai.zeroclaw.chatTools;
          allowed_commands = selfLib.ai.shell.allowedCommands;
        };

        runtime_profiles.main = selfLib.ai.zeroclaw.runtimeProfile // {
          max_context_tokens = selfLib.ai.openrouter.context;
        };
      };

      delegateAgentConfig = {
        agents.${delegateAgent} = {
          workspace = workspaceConfig;
          model_provider = if gpuApi != null then "custom.gpu" else "openrouter.main";
          risk_profile = delegateAgent;
          runtime_profile = delegateAgent;
        };

        risk_profiles.${delegateAgent} = selfLib.ai.zeroclaw.riskProfile // {
          excluded_tools = selfLib.ai.zeroclaw.excludedTools;
          allowed_tools = selfLib.ai.zeroclaw.delegateTools;
          auto_approve = selfLib.ai.zeroclaw.delegateTools;
          allowed_commands = selfLib.ai.shell.allowedCommands;
          delegation_policy.mode = "allow";
        };

        runtime_profiles.main = selfLib.ai.zeroclaw.runtimeProfile // {
          max_context_tokens = if gpuApi != null then gpuApi.context else selfLib.ai.openrouter.context;
        };
      };

      juniorDevAgentConfig = {
        agents.${juniorDevAgent} = {
          workspace = workspaceConfig;
          model_provider = if cpuApi != null then "custom.gpu" else "openrouter.main";
          risk_profile = juniorDevAgent;
          runtime_profile = juniorDevAgent;
          mcp_bundles = [ "dev" ];
        };

        risk_profiles.${juniorDevAgent} = selfLib.ai.zeroclaw.riskProfile // {
          excluded_tools = selfLib.ai.zeroclaw.excludedTools;
          allowed_tools = selfLib.ai.zeroclaw.devTools;
          auto_approve = selfLib.ai.zeroclaw.devTools;
          allowed_commands = selfLib.ai.shell.allowedCommands;
        };

        runtime_profiles.${juniorDevAgent} = selfLib.ai.zeroclaw.runtimeProfile // {
          max_context_tokens = if gpuApi != null then gpuApi.context else selfLib.ai.openrouter.context;
        };
      };

      seniorDevAgentConfig = {
        agents.${seniorDevAgent} = {
          workspace = workspaceConfig;
          model_provider = "openrouter.main";
          risk_profile = seniorDevAgent;
          runtime_profile = seniorDevAgent;
          mcp_bundles = [ "dev" ];
        };

        risk_profiles.${seniorDevAgent} = selfLib.ai.zeroclaw.riskProfile // {
          excluded_tools = selfLib.ai.zeroclaw.excludedTools;
          allowed_tools = selfLib.ai.zeroclaw.devTools;
          auto_approve = selfLib.ai.zeroclaw.devTools;
          allowed_commands = selfLib.ai.shell.allowedCommands;
        };

        runtime_profiles.${seniorDevAgent} = selfLib.ai.zeroclaw.runtimeProfile // {
          max_context_tokens = selfLib.ai.openrouter.context;
        };
      };

      digestAgentConfig = {
        agents.${digestAgent} = {
          workspace = workspaceConfig;
          model_provider = if cpuApi != null then "custom.cpu" else "openrouter.main";
          risk_profile = digestAgent;
          runtime_profile = digestAgent;
          mcp_bundles = [ "digest" ];
          cron_jobs = [ "digest" ];
        };

        risk_profiles.${digestAgent} = selfLib.ai.zeroclaw.riskProfile // {
          excluded_tools = selfLib.ai.zeroclaw.excludedTools;
          allowed_tools = selfLib.ai.zeroclaw.devTools;
          auto_approve = selfLib.ai.zeroclaw.devTools;
          allowed_commands = selfLib.ai.shell.allowedCommands;
        };

        runtime_profiles.${digestAgent} = selfLib.ai.zeroclaw.runtimeProfile // {
          max_context_tokens = if cpuApi != null then cpuApi.context else selfLib.ai.openrouter.context;
        };
      };

      configFile = toml.generate "${name}-config.toml" (
        builtins.foldl' lib.recursiveUpdate { } [
          generalConfig
          mcpConfig
          channelConfig
          providerConfig
          cronConfig
          chatAgentConfig
          delegateAgentConfig
          juniorDevAgentConfig
          seniorDevAgentConfig
          digestAgentConfig
        ]
      );
    in
    lib.mkIf hardware.network {
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
          envsubst < "${configFile}" > "${dataDir}/.config.toml.tmp"
          chmod 0600 "${dataDir}/.config.toml.tmp"
          mv -f "${dataDir}/.config.toml.tmp" "${dataDir}/config.toml"

          mkdir -p ${workspaceDir}
          install -m 0644 ${./agent/AGENTS.md} "${workspaceDir}/AGENTS.md"
          install -m 0644 ${./agent/IDENTITY.md} "${workspaceDir}/IDENTITY.md"
          install -m 0644 ${./agent/SOUL.md} "${workspaceDir}/SOUL.md"
          install -m 0644 ${./agent/TOOLS.md} "${workspaceDir}/TOOLS.md"
          install -m 0644 ${./agent/USER.md} "${workspaceDir}/USER.md"
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
