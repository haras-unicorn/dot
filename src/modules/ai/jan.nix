{ inputs, ... }:

{
  self.nixosModules.jan.value =
    { config, lib, ... }:
    let
      hardware = config.dot.hardware;
    in
    lib.mkIf hardware.browser {
      # NOTE: Jan asks this host for updates on every start, and the check is
      # built into the release, so blocking the host is the only way to stop
      # it. Jan then falls back to the latest release file on GitHub, which
      # gets no session from it
      networking.hosts."0.0.0.0" = [ "apps.jan.ai" ];
    };

  self.homeModules.jan.value =
    {
      config,
      lib,
      pkgs,
      unstablePkgs,
      osConfig,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;

      dataDir = "${config.xdg.dataHome}/Jan/data";
      workspaceDir = "${config.xdg.dataHome}/Jan/workspace";

      # NOTE: Jan is for chatting and the odd question, so the only MCP server
      # it gets is the one that reads pages from the allowed domains
      mcpServerNames = [ "web" ];

      mcpServers = lib.filterAttrs (
        name: _: builtins.elem name mcpServerNames
      ) config.programs.mcp.servers;

      mcpConfig = pkgs.writeText "jan-mcp-config.json" (
        builtins.toJSON {
          mcpServers = builtins.mapAttrs (_: server: {
            command = server.command;
            args = server.args or [ ];
            env = server.env or { };
            active = true;
          }) mcpServers;
        }
      );

      # NOTE: the settings Jan keeps in settings.json, as the stores of its
      # web app name them. Every value there is a store as a JSON string, so
      # each one is its version and the state to merge into it. They are the
      # defaults of Jan, written down so a click in its UI cannot undo them:
      # no analytics, no agent tools, no shell with a network, no blanket
      # approval of MCP tools, no HTML rendered from model output, no update
      # check, and a local API server that stays off at startup, listens on
      # loopback only (the sandbox shares the network of the host), and runs
      # no tools for its clients
      enforcedSettings = {
        setting-agent-tools = {
          version = 0;
          state = {
            agentToolsEnabled = false;
            bashNetworkEnabled = false;
          };
        };
        productAnalytic = {
          version = 0;
          state.productAnalytic = false;
        };
        productAnalyticPrompt = {
          version = 0;
          state.productAnalyticPrompt = false;
        };
        setting-appearance = {
          version = 0;
          state.renderHtmlArtifacts = false;
        };
        setting-general = {
          version = 0;
          state.autoUpdateCheck = false;
        };
        tool-approval = {
          version = 0;
          state.allowAllMCPPermissions = false;
        };
        setting-local-api-server = {
          version = 5;
          state = {
            enableOnStartup = false;
            serverHost = "127.0.0.1";
            enableServerToolExecution = false;
          };
        };
      };

      # NOTE: the AppImage of Jan starts through a hook of the linuxdeploy GTK
      # plugin that sets GDK_BACKEND=x11, and the sandbox has no X11, so GTK
      # cannot open a display. The hook runs inside the app, so no environment
      # variable can beat it. This extracts the same AppImage (the source comes
      # from the package, so there is no second hash to keep) with that line
      # changed, and wraps it the way nixpkgs does. The build fails loudly when
      # the line is not there anymore
      janContents = unstablePkgs.appimageTools.extract {
        pname = "jan";
        version = lib.getVersion unstablePkgs.jan;
        src = unstablePkgs.jan.src;
        postExtract = ''
          chmod --recursive u+w $out
          grep --recursive --null --files-with-matches \
            --include=AppRun --include='*.sh' 'GDK_BACKEND=x11' $out \
            | xargs --null sed --in-place 's/GDK_BACKEND=x11/GDK_BACKEND=wayland/'
        '';
      };

      janWayland = unstablePkgs.appimageTools.wrapAppImage {
        pname = "jan";
        version = lib.getVersion unstablePkgs.jan;
        src = janContents;
        executableName = "Jan-Desktop";
        extraPkgs = packages: [ packages.libgpg-error ];
      };

      # NOTE: the folders are the data folder of Jan, and the ones the webview
      # of the Tauri app keeps for its identifier (jan.ai.app). Anything else
      # Jan writes is gone when it closes
      sandboxedJan = pkgs.harasPackages.makeSandboxedApp {
        name = "jan-sandboxed";
        exe = "${janWayland}/bin/Jan-Desktop";
        home = config.home.homeDirectory;
        dataDirs = [
          "${config.xdg.dataHome}/Jan"
          "${config.xdg.dataHome}/jan.ai.app"
          "${config.xdg.configHome}/jan.ai.app"
          "${config.xdg.cacheHome}/jan.ai.app"
        ];
        workingDirectory = workspaceDir;
      };

      # NOTE: the haraspkgs helpers are not in pkgs.harasPackages of a
      # downstream flake yet, so this extends pkgs with them like stolon does
      harasPackages = (pkgs.extend inputs.haraspkgs.overlays.default).harasPackages;

      # NOTE: Jan rewrites its MCP config and settings from the UI, so this
      # copies a fresh MCP config over the old one and merges the enforced
      # settings into the file on every start, instead of linking read-only
      # files. This runs outside the sandbox, because both have to be in place
      # before Jan reads them
      jan = harasPackages.writeNushellApplication {
        name = "jan";
        runtimeInputs = [ ];
        text = ''
          def --wrapped main [...rest] {
            let data = r#'${dataDir}'#
            let workspace = r#'${workspaceDir}'#
            let app = r#'${lib.getExe sandboxedJan}'#
            let enforced = r#'${builtins.toJSON enforcedSettings}'# | from json
            let file = $data | path join settings.json
            mkdir $data $workspace
            open --raw r#'${mcpConfig}'# | save --force ($data | path join mcp_config.json)

            let settings = if ($file | path exists) { open $file } else { { } }
            let updated = $enforced | transpose key entry | reduce --fold $settings {|row, acc|
              let stored = $acc | default ($row.entry | to json --raw) $row.key | get $row.key | from json
              $acc | upsert $row.key ($stored | merge deep { state: $row.entry.state } | to json --raw)
            }
            $updated | save --force $file

            exec $app ...$rest
          }
        '';
      };
    in
    lib.mkIf hardware.browser {
      home.packages = [ jan ];

      xdg.desktopEntries.jan = {
        name = "Jan";
        exec = lib.getExe jan;
        terminal = false;
      };
    };
}
