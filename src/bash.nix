{ pkgs, lib, config, ... }:

# TODO: prompt after starship like nushell

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
  branch.nixosModule.nixosModule = {
    environment.shells = [ "${pkgs.bashInteractive}/bin/bash" ];
    users.defaultUserShell = "${pkgs.bashInteractive}/bin/bash";
  };

  branch.homeManagerModule.homeManagerModule = {
    programs.bash.enable = true;
    programs.bash.enableCompletion = true;

    programs.bash.initExtra = ''
      ${vars}
      ${aliases}
      ${startup}
    '';

    programs.helix.languages =
      let
        bash-language-server = pkgs.nodePackages.bash-language-server.overrideAttrs (final: prev: {
          buildInputs = (prev.buildInputs or [ ]) ++ [
            pkgs.shellcheck
          ];
        });
      in
      {
        language-server.bash-language-server = {
          command = "${bash-language-server}/bin/bash-language-server";
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
      };

    programs.direnv.enableBashIntegration = true;
    programs.zoxide.enableBashIntegration = true;
    programs.yazi.enableBashIntegration = true;
    programs.starship.enableBashIntegration = true;
  };
}
