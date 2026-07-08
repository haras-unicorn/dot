{
  machines.nixosModules.xdg = { config, ... }: {
    environment.systemPackages = builtins.attrValues config.dot.commands;
  };

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

      copy = pkgs.writeShellApplication {
        name = "copy";
        text = ''
          mkdir -p '${config.xdg.dataHome}'
          cat > '${config.xdg.dataHome}/clipboard'
        '';
      };

      paste = pkgs.writeShellApplication {
        name = "paste";
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
        text = ''
          cat /dev/stdin
        '';
      };

      commands = builtins.attrValues config.dot.commands ++ builtins.attrValues osConfig.dot.commands;

      programs = builtins.attrValues (
        builtins.mapAttrs (_: { package, ... }: package) config.dot.programs
      );

      makeScreenshot =
        name:
        pkgs.writeShellApplication {
          name = "screenshot";
          runtimeInputs = [
            pkgs.fbcat
            config.dot.commands.copy
          ];
          text = ''
            tmp="$(mktemp -d)"
            mkdir -p "$tmp"
            trap 'rm -rf "$tmp"' EXIT

            name="$(date +${config.dot.desktop.timestamp})"
            type="png"
            fbgrab "$tmp/$name.$type"
            copy -t image/$type < "$tmp/$name.$type"

            dir='${config.dot.desktop.screenshots}'
            mkdir -p "$dir"
            mv -f "$tmp/$name.$type" "$dir/$name.$type"
          '';
        };

      entries = builtins.listToAttrs (
        builtins.map ({ package, types, ... }: rec {
          name = "dot-${lib.getName package}";
          value = {
            inherit name;
            exec = "${lib.getExe package} %U";
            terminal = false;
            mimeType = types;
            noDisplay = true;
          };
        }) config.dot.mime.apps
      );

      sinks = builtins.listToAttrs (
        builtins.map (
          { package, types, ... }:
          let
            name = lib.getName package;
          in
          {
            inherit name;
            value = {
              note = "Open";
              inputs = types;
              package = pkgs.writeShellApplication {
                name = "${name}-sink";
                text = ''
                  tmp="$(mktemp)"
                  trap 'rm -f "$tmp"' EXIT
                  cat > "$tmp"
                  ${lib.getExe package} "$tmp"
                '';
              };
            };
          }
        ) config.dot.mime.apps
      );

      mime = lib.mergeAttrsList (
        builtins.map (
          { package, types, ... }:
          builtins.listToAttrs (
            builtins.map (type: {
              name = type;
              value = "dot-${lib.getName package}";
            }) types
          )
        ) config.dot.mime.apps
      );

      apps = builtins.map ({ package, ... }: package) config.dot.mime.apps;
    in
    {
      dot.commands = {
        copy = lib.mkDefault copy;
        paste = lib.mkDefault paste;
        type = lib.mkDefault type;
        screenshot = lib.mkDefault (makeScreenshot "screenshot");
        regionshot = lib.mkDefault (makeScreenshot "regionshot");
        tree = lib.mkDefault tree;
        list = lib.mkDefault list;
      };

      dot.programs.shell.aliases = {
        cat = lib.getExe config.dot.programs.pager.package;
      };

      dot.desktop.keybinds = lib.mkMerge [
        (lib.mkIf hardware.browser [
          {
            mods = [ "super" ];
            key = "w";
            command = lib.getExe config.dot.programs.browser.package;
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
            command = lib.getExe config.dot.commands.screenshot;
          }
        ])
        (lib.mkIf hardware.browser [
          {
            mods = [
              "super"
              "ctrl"
            ];
            key = "p";
            command = lib.getExe config.dot.commands.regionshot;
          }
        ])
        (lib.mkIf hardware.visual [
          {
            mods = [
              "super"
            ];
            key = "return";
            command = lib.getExe config.dot.commands.launcher;
          }
        ])
        (lib.mkIf hardware.visual [
          {
            mods = [
              "super"
            ];
            key = "e";
            command = lib.getExe config.dot.commands.emoji;
          }
        ])
        (lib.mkIf hardware.sound [
          {
            mods = [
              "super"
              "shift"
            ];
            key = "v";
            command = lib.getExe config.dot.commands.volume-up;
          }
        ])
        (lib.mkIf hardware.sound [
          {
            mods = [
              "super"
              "alt"
            ];
            key = "v";
            command = lib.getExe config.dot.commands.volume-down;
          }
        ])
        (lib.mkIf hardware.sound [
          {
            mods = [
              "super"
              "ctrl"
            ];
            key = "v";
            command = lib.getExe config.dot.commands.volume-mute-unmute;
          }
        ])
        (lib.mkIf hardware.sound [
          {
            mods = [
              "super"
            ];
            key = "v";
            command = lib.getExe config.dot.commands.play-pause;
          }
        ])
        (lib.mkIf hardware.graphics [
          {
            mods = [
              "super"
              "shift"
            ];
            key = "b";
            command = lib.getExe config.dot.commands.brightness-up;
          }
        ])
        (lib.mkIf hardware.graphics [
          {
            mods = [
              "super"
              "alt"
            ];
            key = "b";
            command = lib.getExe config.dot.commands.brightness-down;
          }
        ])
      ];

      dot.mime.apps = lib.mkMerge [
        (lib.mkIf hardware.browser [
          {
            package = config.dot.programs.browser.package;
            types = [
              "text/html"
              "x-scheme-handler/http"
              "x-scheme-handler/https"
            ];
          }
        ])
        (lib.mkIf hardware.visual [
          {
            package = config.dot.programs.visual.package;
            types = [
              "text/css"
              "application/javascript"
              "application/json"
              "application/x-sh"
              "application/xhtml+xml"
              "application/xml"
            ];
          }
        ])
        (lib.mkIf hardware.browser [
          {
            package = config.dot.programs.files.package;
            types = [
              "inode/directory"
            ];
          }
        ])
      ];

      dot.processing.sinks = sinks;

      home.packages =
        (with pkgs; [
          xdg-user-dirs
          xdg-utils
          shared-mime-info
          file
        ])
        ++ commands
        ++ programs
        ++ apps;

      home.sessionVariables = lib.mkMerge [
        {
          PAGER = lib.getExe config.dot.programs.pager.package;
        }
        (lib.mkIf hardware.browser {
          BROWSER = lib.getExe config.dot.programs.browser.package;
        })
        (lib.mkIf hardware.visual {
          VISUAL = lib.getExe config.dot.programs.visual.package;
        })
        (lib.mkIf hardware.editor {
          EDITOR = lib.getExe config.dot.programs.editor.package;
        })
      ];

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

      xdg.mime.enable = true;
      xdg.mimeApps.enable = true;
      xdg.desktopEntries = entries;
      xdg.mimeApps.associations.added = mime;
      xdg.mimeApps.defaultApplications = mime;

      home.file = builtins.listToAttrs (
        builtins.concatMap (
          { name, files }:
          builtins.map (file: {
            name = "models/${name}/${lib.getName file}";
            value.source = file;
          }) files
        ) (builtins.attrValues config.dot.ai.models)
      );
    };
}
