{
  machines.homeModules.xdg =
    {
      lib,
      pkgs,
      config,
      osConfig,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;

      terminal = lib.getExe config.dot.programs.terminal.package;
      browser = lib.getExe config.dot.programs.browser.package;
      visual = lib.getExe config.dot.programs.visual.package;
      editor = lib.getExe config.dot.programs.editor.package;

      browserDesktop =
        "${config.dot.programs.browser.package}/share/applications"
        + "/${builtins.baseNameOf (lib.getExe config.dot.programs.browser.package)}.desktop";
      browserMime = {
        "text/html" = browserDesktop;
        "x-scheme-handler/http" = browserDesktop;
        "x-scheme-handler/https" = browserDesktop;
      };

      visualDesktop =
        "${config.dot.programs.visual.package}/share/applications"
        + "/${builtins.baseNameOf (lib.getExe config.dot.programs.visual.package)}.desktop";
      visualMime = {
        "text/css" = visualDesktop;
        "application/javascript" = visualDesktop;
        "application/json" = visualDesktop;
        "application/x-sh" = visualDesktop;
        "application/xhtml+xml" = visualDesktop;
        "application/xml" = visualDesktop;
      };

      copy = pkgs.writeShellApplication {
        name = "copy";
        runtimeInputs = [
          pkgs.coreutils
        ];
        text = ''
          mkdir -p '${config.xdg.dataHome}'
          cat > '${config.xdg.dataHome}/clipboard'
        '';
      };

      paste = pkgs.writeShellApplication {
        name = "paste";
        runtimeInputs = [
          pkgs.coreutils
        ];
        text = ''
          if [ -f '${config.xdg.dataHome}/clipboard' ]; then
            cat '${config.xdg.dataHome}/clipboard'
          fi
        '';
      };

      tree = pkgs.writeShellApplication {
        name = "tree";
        runtimeInputs = [
          pkgs.tree
        ];
        text = ''
          tree
        '';
      };

      list = pkgs.writeShellApplication {
        name = "list";
        text = ''
          ls -la
        '';
      };

      type = pkgs.writeShellApplication {
        name = "type";
        runtimeInputs = [
          pkgs.coreutils
          paste
        ];
        text = ''
          paste
        '';
      };

      type-clipboard = pkgs.writeShellApplication {
        name = "type-clipboard";
        runtimeInputs = [
          pkgs.coreutils
          config.dot.programs.shell.paste
          config.dot.programs.shell.type
        ];
        text = ''
          type "$(paste)"
        '';
      };

      mkScreenshot =
        { name, ... }:
        pkgs.writeShellApplication {
          name = "screenshot";
          runtimeInputs = [
            pkgs.fbcat
            config.dot.programs.shell.copy
            pkgs.coreutils
          ];
          text = ''
            tmp="$(mktemp -d)"
            mkdir -p "$tmp"
            trap 'rm -rf "$tmp"' EXIT

            name="$(date -Iseconds)"
            type="png"
            fbgrab "$tmp/$name.$type"
            copy -t image/$type < "$tmp/$name.$type"

            dir='${config.xdg.userDirs.pictures}/screenshots'
            mkdir -p "$dir"
            mv -f "$tmp/$name.$type" "$dir/$name.$type"
          '';
        };

      screenshot = mkScreenshot { name = "screenshot"; };
      regionshot = mkScreenshot { name = "regionshot"; };

      mime = lib.mkMerge [
        (lib.mkIf hardware.interface browserMime)
        (lib.mkIf hardware.visual visualMime)
      ];
    in
    {
      dot.programs.shell = {
        copy = lib.mkDefault copy;
        paste = lib.mkDefault paste;
        type = lib.mkDefault type;
        screenshot = lib.mkDefault screenshot;
        regionshot = lib.mkDefault regionshot;
        tree = lib.mkDefault tree;
        list = lib.mkDefault list;
      };

      dot.desktop.keybinds = lib.mkMerge [
        (lib.mkIf hardware.interface [
          {
            mods = [ "super" ];
            key = "w";
            command = "${browser}";
          }
        ])
        (lib.mkIf hardware.interface [
          {
            mods = [ "super" ];
            key = "t";
            command = "${terminal}";
          }
        ])
        (lib.mkIf hardware.interface [
          {
            mods = [ "super" ];
            key = "Print";
            command = lib.getExe config.dot.programs.shell.screenshot;
          }
        ])
        (lib.mkIf hardware.interface [
          {
            mods = [
              "super"
              "shift"
            ];
            key = "Print";
            command = lib.getExe config.dot.programs.shell.regionshot;
          }
        ])
        (lib.mkIf hardware.visual [
          {
            mods = [
              "ctrl"
              "alt"
            ];
            key = "v";
            command = lib.getExe type-clipboard;
          }
        ])
      ];

      home.packages = [
        pkgs.xdg-user-dirs
        pkgs.xdg-utils
        pkgs.shared-mime-info

        config.dot.programs.shell.copy
        config.dot.programs.shell.type
        config.dot.programs.shell.paste
        config.dot.programs.shell.screenshot
        config.dot.programs.shell.regionshot
        config.dot.programs.shell.tree
        config.dot.programs.shell.list
      ];

      home.sessionVariables = lib.mkMerge [
        (lib.mkIf hardware.interface {
          BROWSER = "${browser}";
        })
        (lib.mkIf hardware.visual {
          VISUAL = "${visual}";
        })
        (lib.mkIf hardware.editor {
          EDITOR = "${editor}";
        })
      ];

      xdg.mime.enable = true;
      xdg.mimeApps.enable = true;
      xdg.mimeApps.associations.added = mime;
      xdg.mimeApps.defaultApplications = mime;

      xdg.enable = true;
      xdg.userDirs.setSessionVariables = true;
      xdg.userDirs.enable = true;
      xdg.userDirs.createDirectories = true;
      xdg.userDirs.desktop = "${config.home.homeDirectory}/desktop";
      xdg.userDirs.download = "${config.home.homeDirectory}/download";
      xdg.userDirs.music = "${config.home.homeDirectory}/music";
      xdg.userDirs.pictures = "${config.home.homeDirectory}/pictures";
      xdg.userDirs.videos = "${config.home.homeDirectory}/videos";
      xdg.userDirs.templates = "${config.home.homeDirectory}/templates";
      xdg.userDirs.documents = "${config.home.homeDirectory}/documents";
      xdg.userDirs.publicShare = "${config.home.homeDirectory}/public";
      xdg.userDirs.projects = "${config.home.homeDirectory}/projects";
    };
}
