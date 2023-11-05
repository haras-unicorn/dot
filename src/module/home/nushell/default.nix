{ lib, ... }:

with lib;
let
  cfg = config.shell;

  vars = strings.concatStringsSep
    "\n"
    (builtins.map
      (name: ''$env.${name} = $"(${builtins.toString cfg.sessionVariables."${name}"})"'')
      (builtins.attrNames cfg.sessionVariables));

  startup = string.concatStringsSep
    "\n"
    (builtins.map
      (command: "${builtins.toString command}")
      cfg.sessionStartup);
in
{
  options.shell = {
    sessionVariables = mkOption {
      type = with types; lazyAttrsOf (oneOf [ str path int float ]);
      default = { };
      example = { EDITOR = "hx"; };
      description = ''
        Environment variables to set on session start with Nushell.
      '';
    };

    sessionStartup = mkOption {
      type = with types; listOf str;
      default = [ ];
      example = [ "fastfetch" ];
      description = ''
        Commands to execute on session start with Nushell.
      '';
    };
  };

  config = {
    programs.nushell.enable = true;

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

      ${startup}
    '';
  };
}
