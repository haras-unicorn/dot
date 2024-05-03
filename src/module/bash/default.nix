{ lib, config, ... }:

# TODO: prompt after starship like nushell
# TODO: package

let
  cfg = config.dot.shell;

  vars = lib.strings.concatStringsSep
    "\n"
    (builtins.map
      (name: ''export ${name}="$(${builtins.toString cfg.sessionVariables."${name}"})"'')
      (builtins.attrNames cfg.sessionVariables));

  aliases = lib.strings.concatStringsSep
    "\n"
    (builtins.map
      (name: ''alias ${name}="${builtins.toString cfg.aliases."${name}"}"'')
      (builtins.attrNames cfg.aliases));

  startup = lib.strings.concatStringsSep
    "\n"
    (builtins.map
      (command: "${builtins.toString command}")
      cfg.sessionStartup);
in
{
  home.shared = {
    programs.bash.enable = true;
    programs.bash.enableCompletion = true;

    programs.bash.initExtra = ''
      ${vars}

      ${aliases}

      ${startup}
    '';
  };
}
