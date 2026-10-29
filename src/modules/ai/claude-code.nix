{
  self.nixpkgs.config.allowUnfreePackageNames = [ "claude-code" ];

  self.homeModules.claude-code.value =
    {
      pkgs,
      unstablePkgs,
      lib,
      osConfig,
      config,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;

      mcp = pkgs.harasPackages.ai-mcp {
        inherit lib hardware;
        rootRef = "\${CLAUDE_PROJECT_DIR}";
        sshDir = "${config.home.homeDirectory}/.cache/dot/git-mcp";
      };

      mcpServers = lib.mapAttrs (_: server: {
        type = "stdio";
        command = builtins.head server.command;
        args = builtins.tail server.command;
        env = server.environment;
      }) mcp;
    in
    lib.mkIf hardware.editor {
      programs.claude-code = {
        enable = true;

        package = unstablePkgs.claude-code;

        context = ''
          ${builtins.readFile ./AGENTS.md}
          ## Claude Code

          Extra notes for Claude Code on top of everything above.

          - **Use the MCP servers, not the denied built-in tools.** Built-in tools
            like `Read`, `Edit`, `Write`, `Glob`, `Grep` and `Bash` are denied by
            the harness. The one exception is `Read` on `AGENTS.md`, which exists
            only so this file can be loaded. I know it is sitting in your tool
            list and that this file is already in your context, but reaching for
            it just gets a denial and wastes a turn. Use the `filesystem` MCP for
            files, `git` for repository work, and `nix` for commands.
          - **MCP tool schemas can be deferred.** If an MCP tool is listed by name
            but has no schema, load it with `ToolSearch` before calling it.
        '';

        mcpServers = mcpServers;

        settings = {
          editorMode = "vim";
          theme = "dark-ansi";

          autoUpdaterStatus = "disabled";
          disableAutoMode = "disable";
          disableBundledSkills = true;
          disableWorkflows = true;
          disableArtifact = true;
          feedbackSurveyRate = 0;
          includeGitInstructions = false;
          inputNeededNotifEnabled = true;
          promptSuggestionEnabled = false;
          respectGitignore = true;
          wheelScrollAccelerationEnabled = true;
          env = {
            DISABLE_AUTOUPDATER = "1";
          };

          language = "english";
          emojiCompletionEnabled = true;
          syntaxHighlightingDisabled = false;
          showThinkingSummaries = true;

          spellcheck = {
            enabled = true;
            checker = "hunspell";
            language = "en_US";
          };
          availableModels = [
            "claude-opus-5-5"
            "claude-sonnet-5-5"
            "claude-haiku-5-5"
          ];
          model = "claude-sonnet-5-5";
          fallbackModel = [ "claude-haiku-5-5" ];
          effortLevel = "medium";

          autoCompactEnabled = true;
          autoCompactWindow = 400000;
          autoContinueAtUsageLimit = true;

          autoMemoryEnabled = true;

          voice = {
            enabled = true;
            autoSubmit = true;
            mode = "hold";
          };

          strictPluginOnlyCustomization = true;
          strictKnownMarketplaces = [ ];

          sandbox.enabled = false;

          permissions = {
            defaultMode = "manual";
            enableAllProjectMcpServers = false;
            blockReadsOutsideWorkingDirectories = true;
            disableBypassPermissionsMode = "disable";

            allow = [
              "Agent"
              "AskUserQuestion"
              "ToolSearch"
              "WebSearch"
              "WebFetch"
              "ReadMcpResourceTool"
              "ListMcpResourcesTool"
              "TaskCreate"
              "TaskGet"
              "TaskList"
              "TaskUpdate"
              "WaitForMcpServers"
            ]
            ++ builtins.map (mcp: "mcp__plugin_claude-code-home-manager_${mcp}__*") (
              builtins.attrNames mcpServers
            );

            deny = [
              # NOTE: otherwise it can't read AGENTS.md...
              "Read(**/*)"
              "Read(!AGENTS.md)"
              "Artifact"
              "Bash"
              "CronCreate"
              "CronDelete"
              "CronList"
              "Edit"
              "EnterPlanMode"
              "EnterWorktree"
              "ExitPlanMode"
              "ExitWorktree"
              "Glob"
              "Grep"
              "ListAgents"
              "LSP"
              "Monitor"
              "NotebookEdit"
              "PowerShell"
              "RemoteTrigger"
              "ReportFindings"
              "ScheduleWakeup"
              "SendFeedback"
              "SendMessage"
              "SendUserFile"
              "ShareOnboardingGuide"
              "Skill"
              "SubagentHandback"
              "TaskStop"
              "TodoWrite"
              "Workflow"
              "Write"
              "PushNotification"
            ];
          };
        };
      };
    };
}

# NOTE: keeping this here just in case
# sandbox = {
#   enabled = true;
#   failIfUnavailable = true;
#   enableWeakerNestedSandbox = false;
#   enableWeakerNetworkIsolation = false;
#   allowNestedUserNamespaces = false;
#   autoAllowBashIfSandboxed = true;
#   allowUnsandboxedCommands = false;

#   ripgrep.command = lib.getExe config.programs.ripgrep.package;
#   bwrapPath = lib.getExe pkgs.bubblewrap;
#   socatPath = lib.getExe pkgs.socat;

#   network = {
#     allowLocalBinding = false;
#     strictAllowlist = true;
#     allowedDomains = [
#       "claude.com"
#       "*.claude.com"
#       "github.com"
#       "*.github.com"
#       "raw.githubusercontent.com"
#       "nixos.org"
#       "*.nixos.org"
#       "nix.dev"
#       "kernel.org"
#       "*.kernel.org"
#       "developer.mozilla.org"
#       "docs.rs"
#       "doc.rust-lang.org"
#       "rfc-editor.org"
#       "arxiv.org"
#       "wikipedia.org"
#       "*.wikipedia.org"
#       "index.hr"
#       "arstechnica.com"
#       "bleepingcomputer.com"
#     ];
#   };
# };
