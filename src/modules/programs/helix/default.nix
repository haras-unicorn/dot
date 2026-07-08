# FIXME: stylix conflicts
# TODO: proper theming as explained here: https://docs.helix-editor.com/themes.html

{
  machines.homeModules.helix =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.dot.programs.editor;

      editor = lib.getExe cfg.package;
    in
    {
      dot.programs.editor.package = config.programs.helix.package;

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
