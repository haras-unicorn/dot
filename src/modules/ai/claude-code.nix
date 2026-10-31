{ self, selfLib, ... }:

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

      # NOTE: the built-in terminal notification does not say which session it
      # came from, so this one is titled with the project folder instead
      notify = pkgs.writeShellApplication {
        name = "claude-code-notify";
        runtimeInputs = [
          pkgs.jq
          pkgs.libnotify
          pkgs.coreutils
        ];
        text = ''
          input="$(cat)"
          project="$(basename "$(jq -r '.cwd' <<<"$input")")"
          message="$(jq -r '.message // "Needs your attention"' <<<"$input")"
          notify-send --app-name "Claude Code" --icon ${self}/assets/icons/claude-code.svg "$project" "$message"
        '';
      };
    in
    lib.mkIf hardware.editor {
      programs.claude-code = {
        enable = true;

        package = unstablePkgs.claude-code;

        context = ''
          ${selfLib.ai.agents}
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
          - **Use the `web` MCP's `web_fetch` when you need a page verbatim.** The
            built-in `WebFetch` runs the page through a small model that
            summarizes and may refuse to quote it. `web_fetch` returns the page
            itself, as markdown or as an image, so use it whenever the exact
            text matters. Long pages come back in slices: keep calling with the
            returned `next_offset` (and the same `mode`) until it is gone. Use
            `mode: full` when the readable extraction might drop something you
            need.
        '';

        enableMcpIntegration = true;

        skills = selfLib.ai.skills;

        settings = {
          hooks.Notification = [
            {
              hooks = [
                {
                  type = "command";
                  command = lib.getExe notify;
                }
              ];
            }
          ];

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
          preferredNotifChannel = "notifications_disabled";
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
          effortLevel = "high";

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
              builtins.attrNames config.programs.mcp.servers
            );

            deny = [
              # NOTE: only `web_fetch` is wanted from the web MCP, searching
              # stays with the built-in tool
              "mcp__plugin_claude-code-home-manager_web__web_search"
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
