{ lib, config, ... }:

# TODO: add dot prefix

with lib;
let
  cfg = config.shell;

  vars = strings.concatStringsSep
    "\n"
    (builtins.map
      (name: ''export ${name} = "$(${builtins.toString cfg.sessionVariables."${name}"})"'')
      (builtins.attrNames cfg.sessionVariables));

  aliases = strings.concatStringsSep
    "\n"
    (builtins.map
      (name: ''alias ${name} = ${builtins.toString cfg.aliases."${name}"}'')
      (builtins.attrNames cfg.aliases));

  startup = strings.concatStringsSep
    "\n"
    (builtins.map
      (command: "${builtins.toString command}")
      cfg.sessionStartup);
in
{
  programs.bash.enable = true;

  programs.bash.initExtra = ''
    ${vars}

    ${aliases}

    ${startup}
  '';
}
