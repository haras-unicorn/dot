{ lib, pkgs, config, ... }:

let
  cfg = config.dot.editor;
in
{
  home.shared = {
    programs.lulezojne.config.plop = [
      {
        template = builtins.readFile ./lulezojne.toml;
        "in" = "${config.xdg.configHome}/helix/themes/lulezojne.toml";
        "then" = {
          command = "pkill";
          args = [ "--signal" "SIGUSR1" "hx" ];
        };
      }
    ];

    programs.helix.enable = true;
    programs.helix.package =
      (p: yes: no: lib.mkMerge [
        (lib.mkIf p yes)
        (lib.mkIf (!p) no)
      ])
        (cfg.bin == "hx")
        cfg.package
        pkgs.helix;

    programs.helix.settings = builtins.fromTOML (builtins.readFile ./config.toml);

    programs.helix.languages = {
      language-server = {
        nil = { command = "${pkgs.nil}/bin/nil"; };
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
  };
}
