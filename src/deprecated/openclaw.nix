{ inputs, ... }:

# NOTE: https://github.com/openclaw/nix-openclaw
# nix-openclaw.url = "github:openclaw/nix-openclaw/refs/tags/v2026.7.1";
# nix-openclaw.inputs.nixpkgs.follows = "nixpkgs";
# nix-openclaw.inputs.home-manager.follows = "home-manager";

{
  self.lib.deprecated.homeModules.openclaw =
    {
      pkgs,
      lib,
      osConfig,
      config,
      unstablePkgs,
      ...
    }:
    let
      stateDir = "${config.home.homeDirectory}/.openclaw";

      gatewayPort = 18789;

      hardware = osConfig.dot.hardware;

      controlUi = osConfig.dot.programs.chromium.launch {
        name = "openclaw";
        address = "http://127.0.0.1:${builtins.toString gatewayPort}";
      };
    in
    {
      imports = [
        inputs.nix-openclaw.homeManagerModules.openclaw
      ];

      nixpkgs.overlays = [
        # nix-openclaw pins nodejs_22 (22.23.1 in nixpkgs 26.05), whose
        # embedded SQLite 3.51.2 has a WAL corruption bug that OpenClaw
        # refuses to run against. Use unstable's nodejs_22 (embeds SQLite
        # 3.51.3+), keeping the same major version.
        (final: prev: {
          nodejs_22 = unstablePkgs.nodejs_22;
        })
        inputs.nix-openclaw.overlays.default
      ];

      programs.openclaw = {
        enable = true;
        workspaceDir = "${stateDir}/workspace";

        # runtimePlugins = [
        #   "matrix"
        # ];

        # published build (2026.7.2-beta.7) requires plugin API >=2026.7.2,
        # but this host is 2026.7.1, so discovery is skipped.
        # runtimePluginSources = [
        #   {
        #     id = "duckduckgo";
        #     spec = "npm:@openclaw/duckduckgo-plugin@2026.7.2-beta.7";
        #     hash = "sha256-i9nhNWL+KuhDFDTZiUPsGRhm4+O1Os5Sh8tSyRlVm9s=";
        #   }
        # ];

        runtimePackages = [
          pkgs.github-mcp-server
          pkgs.git
          pkgs.nodejs
          pkgs.nix
        ];

        config = {
          gateway.auth.mode = "none";

          agents.defaults = {
            model = "deepseek/deepseek-v4-flash";
          };

          agents.list = [
            {
              id = "main";
              default = true;
              name = "Main";
            }
          ];

          tools = {
            fs.workspaceOnly = true;
            exec = {
              host = "gateway";
              mode = "ask";
              applyPatch.workspaceOnly = true;
            };

            # (see the commented-out runtimePluginSources above).
            # web.search = {
            #   enabled = true;
            #   provider = "duckduckgo";
            #   maxResults = 5;
            # };
            web.fetch = {
              enabled = true;
              readability = true;
            };
          };

          # channels.matrix = {
          #   enabled = true;
          #   dm.policy = "disabled";
          #   groupPolicy = "open";
          #   autoJoin = "off";
          #   encryption = true;
          # };

          mcp.servers.github = {
            command = "github-mcp-server";
            args = [ "stdio" ];
            env.GITHUB_PERSONAL_ACCESS_TOKEN = "\${GITHUB_PERSONAL_ACCESS_TOKEN}";
          };

          models.providers.deepseek = {
            baseUrl = "https://api.deepseek.com/v1";
            api = "openai-completions";
            apiKey = {
              source = "env";
              provider = "default";
              id = "DEEPSEEK_API_KEY";
            };
            models = [
              {
                id = "deepseek-v4-flash";
                name = "DeepSeek V4 Flash";
              }
            ];
          };
        };
      };

      systemd.user.services.openclaw-gateway = {
        Install = {
          WantedBy = [ "default.target" ];
        };
        Service = {
          WorkingDirectory = stateDir;
          StandardOutput = lib.mkForce "journal";
          StandardError = lib.mkForce "journal";
          ProtectHome = "read-only";
          ReadWritePaths = [ stateDir ];
          ProtectSystem = "strict";
          PrivateTmp = true;
          PrivateDevices = true;
          NoNewPrivileges = true;
          LockPersonality = true;
          RestrictAddressFamilies = "AF_INET AF_INET6";
          RestrictSUIDSGID = true;
          SystemCallArchitectures = "native";
        };
      };

      home.activation.openclawStateDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        mkdir -p ${stateDir}/workspace
        chmod 700 ${stateDir}
      '';

      home.packages = lib.optionals hardware.browser [
        controlUi
      ];

      xdg.desktopEntries.openclaw = lib.mkIf hardware.browser {
        name = "OpenClaw";
        exec = lib.getExe controlUi;
        terminal = false;
      };
    };
}
