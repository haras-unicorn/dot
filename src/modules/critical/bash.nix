{
  self.nixosModules.bash.value =
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

  self.homeModules.bash.value =
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

      programs.readline.enable = true;
      programs.readline.variables = {
        editing-mode = "vi";
        # NOTE: negative, zero, non-numeric makes
        # exiting normal mode wait until you press another key
        keyseq-timeout = 1;
        show-mode-in-prompt = true;
        vi-ins-mode-string = config.dot.prompt.readlineIndicators.insert;
        vi-cmd-mode-string = config.dot.prompt.readlineIndicators.normal;
      };

      # NOTE: readline steps the cursor back when leaving insert mode, like
      # vi does, so this steps it forward again to stay on the same character
      programs.readline.extraConfig = ''
        set keymap vi-insert
        "\C-x\C-v": vi-movement-mode
        "\e": "\C-x\C-vl"
      '';

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
