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

      browser = lib.getExe config.dot.programs.browser.package;
      visual = lib.getExe config.dot.programs.visual.package;
      editor = lib.getExe config.dot.programs.editor.package;

      browserDesktopName = "dot-browser.desktop";
      browserMime = [
        "text/html"
        "x-scheme-handler/http"
        "x-scheme-handler/https"
      ];

      visualDesktopName = "dot-visual.desktop";
      visualMime = [
        "text/css"
        "application/javascript"
        "application/json"
        "application/x-sh"
        "application/xhtml+xml"
        "application/xml"

      ];

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
        (lib.mkIf hardware.browser (
          builtins.listToAttrs (
            builtins.map (name: {
              inherit name;
              value = browserDesktopName;
            }) browserMime
          )
        ))
        (lib.mkIf hardware.visual (
          builtins.listToAttrs (
            builtins.map (name: {
              inherit name;
              value = visualDesktopName;
            }) visualMime
          )
        ))
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

      dot.desktop.keybinds = lib.mkIf hardware.typing (
        lib.mkMerge [
          (lib.mkIf hardware.browser [
            {
              mods = [ "super" ];
              key = "w";
              command = browser;
            }
          ])
          (lib.mkIf hardware.browser [
            {
              mods = [ "super" ];
              key = "t";
              command = lib.getExe config.dot.programs.terminal.package;
            }
          ])
          (lib.mkIf hardware.browser [
            {
              mods = [ "super" ];
              key = "p";
              command = lib.getExe config.dot.programs.shell.screenshot;
            }
          ])
          (lib.mkIf hardware.browser [
            {
              mods = [
                "super"
                "ctrl"
              ];
              key = "p";
              command = lib.getExe config.dot.programs.shell.regionshot;
            }
          ])
          (lib.mkIf hardware.visual [
            {
              mods = [
                "super"
              ];
              key = "return";
              command = lib.getExe config.dot.programs.shell.launcher;
            }
          ])
          (lib.mkIf hardware.visual [
            {
              mods = [
                "super"
              ];
              key = "e";
              command = lib.getExe config.dot.programs.shell.emoji;
            }
          ])
          (lib.mkIf hardware.sound [
            {
              mods = [
                "super"
                "shift"
              ];
              key = "v";
              command = lib.getExe config.dot.programs.shell.volume-up;
            }
          ])
          (lib.mkIf hardware.sound [
            {
              mods = [
                "super"
                "alt"
              ];
              key = "v";
              command = lib.getExe config.dot.programs.shell.volume-down;
            }
          ])
          (lib.mkIf hardware.sound [
            {
              mods = [
                "super"
                "ctrl"
              ];
              key = "v";
              command = lib.getExe config.dot.programs.shell.volume-mute-unmute;
            }
          ])
          (lib.mkIf hardware.sound [
            {
              mods = [
                "super"
              ];
              key = "v";
              command = lib.getExe config.dot.programs.shell.play-pause;
            }
          ])
          (lib.mkIf hardware.graphics [
            {
              mods = [
                "super"
                "shift"
              ];
              key = "b";
              command = lib.getExe config.dot.programs.shell.brightness-up;
            }
          ])
          (lib.mkIf hardware.graphics [
            {
              mods = [
                "super"
                "alt"
              ];
              key = "b";
              command = lib.getExe config.dot.programs.shell.brightness-down;
            }
          ])
        ]
      );

      home.packages =
        (with pkgs; [
          xdg-user-dirs
          xdg-utils
          shared-mime-info
        ])
        ++ (with config.dot.programs.shell; [
          copy
          type
          paste
          screenshot
          regionshot
          tree
          list
          dmenu
          launcher
          emoji
          volume-up
          volume-down
          brightness-up
          brightness-down
        ]);

      home.sessionVariables = lib.mkMerge [
        (lib.mkIf hardware.browser {
          BROWSER = "${browser}";
        })
        (lib.mkIf hardware.visual {
          VISUAL = "${visual}";
        })
        (lib.mkIf hardware.editor {
          EDITOR = "${editor}";
        })
      ];

      xdg.desktopEntries = lib.mkMerge [
        (lib.mkIf hardware.browser {
          dot-browser = {
            name = "Dot Browser";
            exec = "${browser} %U";
            terminal = false;
            mimeType = browserMime;
            noDisplay = true;
          };
        })
        (lib.mkIf hardware.visual {
          dot-visual = {
            name = "Dot Visual";
            exec = "${visual} %U";
            terminal = false;
            mimeType = visualMime;
            noDisplay = true;
          };
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
