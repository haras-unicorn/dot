{ lib, pkgs, config, ... }:

# FIXME: stylix conflicts
# TODO: proper theming as explained here: https://docs.helix-editor.com/themes.html

let
  cfg = config.dot.editor;

  editor = "${cfg.package}/bin/${cfg.bin}";
in
{
  config = {
    editor = { package = pkgs.helix; bin = "hx"; };
  };

  home = {
    programs.helix.enable = true;

    programs.helix.settings = builtins.fromTOML (builtins.readFile ./config.toml);

    home.activation = {
      helixReloadAction = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        ${pkgs.procps}/bin/pkill --signal "SIGUSR1" "${cfg.bin}" || true
      '';
    };

    programs.helix.languages = {
      language-server = {
        nil = {
          command = "${pkgs.nil}/bin/nil";
        };
        taplo = { command = "${pkgs.taplo}/bin/taplo"; args = [ "server" ]; };
        yaml-language-server = {
          command = "${pkgs.yaml-language-server}/bin/yaml-language-server";
          args = [ "--stdio" ];
        };
        vscode-json-language-server = {
          command = "${pkgs.nodePackages.vscode-json-languageserver}/bin/vscode-json-language-server";
          args = [ "--stdio" ];
          config = {
            provideFormatter = true;
            format = { enable = true; };
            json = { validate = { enable = true; }; };
          };
        };
        marksman = { command = "${pkgs.marksman}/bin/marksman"; args = [ "server" ]; };
      };

      language = [
        {
          name = "nix";
          auto-format = true;
          formatter = { command = "${pkgs.nixpkgs-fmt}/bin/nixpkgs-fmt"; };
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
            command = "${pkgs.nodePackages.prettier}/bin/prettier";
            args = [ "--parser" "yaml" ];
          };
          language-servers = [ "yaml-language-server" ];
        }
        {
          name = "json";
          auto-format = true;
          formatter = {
            command = "${pkgs.nodePackages.prettier}/bin/prettier";
            args = [ "--parser" "json" ];
          };
          language-servers = [ "vscode-json-language-server" ];
        }
        {
          name = "markdown";
          auto-format = true;
          formatter = {
            command = "${pkgs.nodePackages.prettier}/bin/prettier";
            args = [ "--parser" "json" ];
          };
        }
        {
          name = "xml";
          auto-format = true;
          formatter = { command = "${pkgs.html-tidy}/bin/tidy"; args = [ "-xml" "-i" ]; };
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
