{ pkgs, lib, config, ... }:

let
  cfg = config.dot.shell;

  withPackage = x:
    (p: yes: no: lib.mkMerge [
      (lib.mkIf p yes)
      (lib.mkIf (!p) no)
    ])
      (cfg.bin == "nu")
      (x cfg.package)
      (x pkgs.nushell);

  vars = lib.strings.concatStringsSep
    "\n"
    (builtins.map
      (name: ''$env.${name} = $"(${builtins.toString cfg.sessionVariables."${name}"})"'')
      (builtins.attrNames cfg.sessionVariables));

  aliases = lib.strings.concatStringsSep
    "\n"
    (builtins.map
      (name: ''alias ${name} = ${builtins.toString cfg.aliases."${name}"}'')
      (builtins.attrNames cfg.aliases));

  startup = lib.strings.concatStringsSep
    "\n"
    (builtins.map
      (command: "${builtins.toString command}")
      cfg.sessionStartup);
in
{
  config = {
    home = {
      programs.nushell.enable = true;
      programs.nushell.package = withPackage (package: package);

      programs.nushell.environmentVariables = {
        PROMPT_INDICATOR_VI_INSERT = "'󰞷 '";
        PROMPT_INDICATOR_VI_NORMAL = "' '";
      };

      programs.nushell.envFile.text = ''
        ${builtins.readFile ./env.nu}

        ${vars}
      '';

      programs.nushell.configFile.text = ''
        ${builtins.readFile ./config.nu}

        ${aliases}

        ${startup}
      '';

      home.packages = [ pkgs.nufmt ];

      programs.helix.languages = withPackage (package: {
        language-server.nu-lsp = {
          command = "${package}/bin/nu";
          args = [ "--lsp" ];
        };

        language = [{
          name = "nu";
          language-servers = [ "nu-lsp" ];
          formatter = {
            command = "${pkgs.nufmt}/bin/nufmt";
          };
          auto-format = true;
        }];
      });
    };
  };
}
