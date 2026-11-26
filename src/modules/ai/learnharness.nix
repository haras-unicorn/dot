{ inputs, ... }:

{
  self.homeModules.learnharness.value =
    {
      config,
      lib,
      pkgs,
      osConfig,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;

      # NOTE: the app keeps everything under the folder named after it,
      # including its graph database, settings and saved keys (the name is set
      # in its main process)
      dataDir = "${config.xdg.configHome}/LearnHarness";

      # NOTE: the one folder of the home directory the app can read, and it
      # cannot change anything in it. Its file tools are always on, so this is
      # where the things that it may find are put
      workspaceDir = "${config.xdg.dataHome}/LearnHarness";

      # NOTE: the settings the app reads from settings.json, by its own shape.
      # Only `research`, `demo`, `visual` and `pdf` can be switched off in its
      # UI, and a tool that is not listed stays on. Research is off because it
      # needs a search key that is not set. The file access policy keeps the
      # file tools in the workspace, and updates are off because the app cannot
      # replace itself in the Nix store
      enforcedSettings = {
        general.autoUpdate = false;
        agent = {
          tools.research = false;
          fileAccess = {
            restricted = true;
            folders = [ workspaceDir ];
          };
        };
      };

      sandboxedLearnharness = pkgs.harasPackages.makeSandboxedApp {
        name = "learnharness-sandboxed";
        exe = lib.getExe harasPackages.learnharness;
        home = config.home.homeDirectory;
        dataDirs = [ dataDir ];
        readOnlyDirs = [ workspaceDir ];
        env.ELECTRON_OZONE_PLATFORM_HINT = "wayland";
      };

      # NOTE: the haraspkgs helpers are not in pkgs.harasPackages of a
      # downstream flake yet, so this extends pkgs with them like stolon does
      harasPackages = (pkgs.extend inputs.haraspkgs.overlays.default).harasPackages;

      # NOTE: the app rewrites settings.json from its UI, so this merges the
      # enforced values into the file on every start and leaves the other
      # choices (models, theme) alone. This runs outside the sandbox, because
      # the settings have to be in place before the app reads them
      learnharness = harasPackages.writeNushellApplication {
        name = "learnharness";
        runtimeInputs = [ ];
        text = ''
          def --wrapped main [...rest] {
            let data = r#'${dataDir}'#
            let app = r#'${lib.getExe sandboxedLearnharness}'#
            let enforced = r#'${builtins.toJSON enforcedSettings}'# | from json
            let file = $data | path join data settings.json
            mkdir ($file | path dirname)

            let settings = if ($file | path exists) { open $file } else { { version: 1 } }
            $settings | merge deep $enforced | save --force $file

            exec $app ...$rest
          }
        '';
      };
    in
    lib.mkIf hardware.browser {
      home.packages = [ learnharness ];

      xdg.desktopEntries.learnharness = {
        name = "LearnHarness";
        exec = lib.getExe learnharness;
        terminal = false;
      };
    };
}
