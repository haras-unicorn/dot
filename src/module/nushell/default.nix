{ pkgs, lib, config, ... }:

# TODO: add dot prefix

let
  cfg = config.shell;

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
  options.shell = {
    sessionVariables = lib.mkOption {
      type = with lib.types; lazyAttrsOf (oneOf [ str path int float ]);
      default = { };
      example = { EDITOR = "hx"; };
      description = ''
        Environment variables to set on session start with Nushell.
      '';
    };

    aliases = lib.mkOption {
      type = with lib.types; lazyAttrsOf str;
      default = { };
      example = { rm = "rm -i"; };
      description = ''
        Aliases to use in Nushell.
      '';
    };

    sessionStartup = lib.mkOption {
      type = with lib.types; listOf str;
      default = [ ];
      example = [ "fastfetch" ];
      description = ''
        Commands to execute on session start with Nushell.
      '';
    };
  };

  config = {
    home.shared = {
      programs.nushell.enable = true;

      programs.nushell.environmentVariables = {
        PROMPT_INDICATOR_VI_INSERT = "'󰞷 '";
        PROMPT_INDICATOR_VI_NORMAL = "' '";
      };

      programs.nushell.package = pkgs.nushell.override {
        additionalFeatures = (p: p ++ [ "dataframe" ]);
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
    };
  };
}
