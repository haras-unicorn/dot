# TODO: prompt after starship like nushell

{
  machines.nixosModules.bash =
    {
      lib,
      pkgs,
      ...
    }:
    {
      dot.desktop.startup = [
        {
          name = "Bash";
          command = "${lib.getExe pkgs.bashInteractive} --login";
        }
      ];

      environment.shells = [ pkgs.bashInteractive ];
      users.defaultUserShell = pkgs.bashInteractive;

      security.sudo.keepTerminfo = true;
      environment.enableAllTerminfo = true;
    };

  machines.homeModules.bash =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.dot.programs.shell;

      vars = lib.strings.concatStringsSep "\n" (
        builtins.map (name: ''export ${name}="$(${builtins.toString cfg.sessionVariables."${name}"})"'') (
          builtins.attrNames cfg.sessionVariables
        )
      );

      aliases = lib.strings.concatStringsSep "\n" (
        builtins.map (name: ''alias ${name}="${builtins.toString cfg.aliases."${name}"}"'') (
          builtins.filter (name: !(lib.strings.hasInfix " " name)) (builtins.attrNames cfg.aliases)
        )
      );

      startup = lib.strings.concatStringsSep "\n" (
        builtins.map (command: "${builtins.toString command}") cfg.sessionStartup
      );
    in
    {
      programs.bash.enable = true;
      programs.bash.enableCompletion = true;
      programs.bash.package = pkgs.bashInteractive;

      programs.bash.initExtra = ''
        ${vars}
        ${aliases}
        ${startup}
      '';

      programs.helix.languages =
        let
          bash-language-server = pkgs.bash-language-server.overrideAttrs (
            final: prev: {
              buildInputs = (prev.buildInputs or [ ]) ++ [
                pkgs.shellcheck
              ];
            }
          );
        in
        {
          language-server.bash-language-server = {
            command = lib.getExe bash-language-server;
            args = [ "start" ];
          };

          language = [
            {
              name = "bash";
              language-servers = [ "bash-language-server" ];
              formatter = {
                command = lib.getExe pkgs.shfmt;
              };
              auto-format = true;
            }
          ];
        };

      home.shell.enableBashIntegration = true;
    };
}
