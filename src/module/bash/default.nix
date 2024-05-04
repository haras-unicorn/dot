{ pkgs, lib, config, ... }:

# TODO: prompt after starship like nushell
# TODO: package

let
  cfg = config.dot.shell;

  withPackage = x:
    (p: yes: no: lib.mkMerge [
      (lib.mkIf p yes)
      (lib.mkIf (!p) no)
    ])
      (cfg.bin == "bash")
      (x cfg.package)
      (x pkgs.bashInteractive);

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

    programs.helix.languages = withPackage (package: {
      language-server.bash-language-server = {
        command = "${pkgs.nodePackages.bash-language-server}/bin/bash-language-server";
        args = [ "start" ];
      };

      language = [{
        name = "bash";
        language-servers = [ "bash-language-server" ];
        formatter = {
          command = "${pkgs.shfmt}/bin/shfmt";
        };
        auto-format = true;
      }];
    });
  };
}
