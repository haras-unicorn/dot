{ lib, pkgs, config, ... }:

# TODO: proper theming as explained here: https://docs.helix-editor.com/themes.html

let
  cfg = config.dot.editor;

  withPkg = todo:
    (p: yes: no: lib.mkMerge [
      (lib.mkIf p yes)
      (lib.mkIf (!p) no)
    ])
      (cfg.bin == "hx")
      (todo cfg.package)
      (todo pkgs.helix);

  bootstrap = config.dot.colors.bootstrap;
in
{
  home.shared = {
    programs.helix.enable = true;
    programs.helix.package = withPkg (pkg: pkg);

    programs.helix.settings = builtins.fromTOML (builtins.readFile ./config.toml);

    home.activation = {
      helixReloadAction = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        ${pkgs.procps}/bin/pkill --signal "SIGUSR1" "${cfg.bin}" || true
      '';
    };

    xdg.configFile."helix/themes/colors.toml".text = ''
      ${builtins.readFile ./colors.toml}

      [palette]

      transparent = "${bootstrap.background.normal.hex}"

      background = "${bootstrap.background.normal.hex}"
      backgroundAlternate = "${bootstrap.background.alternate.hex}"

      text = "${bootstrap.text.normal.hex}"
      textAlternate = "${bootstrap.text.alternate.hex}"

      primary = "${bootstrap.primary.normal.hex}"
      secondary = "${bootstrap.secondary.normal.hex}"
      accent = "${bootstrap.accent.normal.hex}"
    '';

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
        edit = withPkg (pkg: pkg + "/bin/${cfg.bin} -- {{filename}}");
        editAtLine = withPkg (pkg: pkg + "/bin/${cfg.bin} -- {{filename}}:{{line}}");
        editAtLineAndWait = withPkg (pkg: pkg + "/bin/${cfg.bin} -- {{filename}}:{{line}}");
        openDirInEditor = withPkg (pkg: pkg + "/bin/${cfg.bin} -- {{dir}}");
        suspend = true;
      };
    };
  };
}
