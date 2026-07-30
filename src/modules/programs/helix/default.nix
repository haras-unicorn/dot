{ selfLib, ... }:

{
  machines.homeModules.helix =
    {
      osConfig,
      config,
      lib,
      pkgs,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;

      package = config.programs.helix.package;

      editor = lib.getExe package;

      terminal = lib.getExe config.dot.programs.terminal.package;

      nodeCommand = if hardware.graphics then ''${terminal} hx "$tmp"'' else ''hx "$tmp"'';

      source = pkgs.writeShellApplication {
        name = "helix-editor-source";
        runtimeInputs = [ package ];
        text = ''
          tmp="$(mktemp)"
          trap 'rm -f "$tmp"' EXIT
          ${nodeCommand} &>/dev/null
          cat "$tmp"
        '';
      };

      node = pkgs.writeShellApplication {
        name = "helix-editor-node";
        runtimeInputs = [ package ];
        text = ''
          tmp="$(mktemp)"
          trap 'rm -f "$tmp"' EXIT
          cat > "$tmp"
          ${nodeCommand} &>/dev/null
        '';
      };
    in
    lib.mkIf hardware.editor {
      dot.programs.editor.package = package;

      dot.processing = {
        sources.helix-editor = {
          note = "Write text";
          tags = [
            "text"
            "write"
          ];
          output = "text/plain";
          package = source;
        };

        nodes.helix-editor = {
          note = "Edit text";
          tags = [
            "text"
            "editor"
          ];
          inputs = selfLib.mime.editor;
          output = "detect";
          package = node;
        };
      };

      programs.helix.enable = true;

      programs.helix.settings = builtins.fromTOML (builtins.readFile ./config.toml);

      home.activation = {
        helixReloadAction = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          ${lib.getExe' pkgs.procps "pkill"} --signal "SIGUSR1" "${builtins.baseNameOf editor}" || true
        '';
      };

      programs.helix.languages = {
        language-server = {
          nil = {
            command = lib.getExe pkgs.nil;
          };
          taplo = {
            command = lib.getExe pkgs.taplo;
            args = [ "server" ];
          };
          yaml-language-server = {
            command = lib.getExe pkgs.yaml-language-server;
            args = [ "--stdio" ];
          };
          vscode-json-language-server = {
            command = lib.getExe pkgs.vscode-json-languageserver;
            args = [ "--stdio" ];
            config = {
              provideFormatter = true;
              format = {
                enable = true;
              };
              json = {
                validate = {
                  enable = true;
                };
              };
            };
          };
          marksman = {
            command = lib.getExe pkgs.marksman;
            args = [ "server" ];
          };
        };

        language = [
          {
            name = "nix";
            auto-format = true;
            formatter = {
              command = lib.getExe pkgs.nixfmt;
              args = [
                "--filename"
                "%{buffer_name}"
              ];

            };
            language-servers = [ "nil" ];
          }
          {
            name = "toml";
            auto-format = true;
            language-servers = [ "taplo" ];
          }
          {
            name = "yaml";
            auto-format = true;
            formatter = {
              command = lib.getExe pkgs.prettier;
              args = [
                "--parser"
                "yaml"
              ];
            };
            language-servers = [ "yaml-language-server" ];
          }
          {
            name = "json";
            auto-format = true;
            formatter = {
              command = lib.getExe pkgs.prettier;
              args = [
                "--parser"
                "json"
              ];
            };
            language-servers = [ "vscode-json-language-server" ];
          }
          {
            name = "markdown";
            auto-format = true;
            formatter = {
              command = lib.getExe pkgs.prettier;
              args = [
                "--parser"
                "json"
              ];
            };
          }
          {
            name = "xml";
            auto-format = true;
            formatter = {
              command = lib.getExe pkgs.html-tidy;
              args = [
                "-xml"
                "-i"
              ];
            };
          }
        ];
      };

      programs.lazygit.settings = {
        os = {
          edit = "${editor} -- {{filename}}";
          editAtLine = "${editor} -- {{filename}}:{{line}}";
          editAtLineAndWait = "${editor} -- {{filename}}:{{line}}";
          openDirInEditor = "${editor} -- {{dir}}";
          suspend = true;
        };
      };
    };
}
