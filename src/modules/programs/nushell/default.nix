{
  self.nixosModules.nushell.value =
    { lib, pkgs, ... }:
    let
      exe = lib.getExe pkgs.nushell;
    in
    {
      dot.desktop.startup = [
        {
          name = "Nushell";
          command = "${exe} --login";
        }
      ];

      environment.shells = [ exe ];
    };

  self.homeModules.nushell.value =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.dot.programs.shell;

      vars = lib.strings.concatStringsSep "\n" (
        builtins.map (name: ''$env.${name} = $"(${builtins.toString cfg.sessionVariables."${name}"})"'') (
          builtins.attrNames cfg.sessionVariables
        )
      );

      aliases = lib.strings.concatStringsSep "\n" (
        builtins.map (name: ''alias "${name}" = ${builtins.toString cfg.aliases."${name}"}'') (
          builtins.attrNames cfg.aliases
        )
      );

      startup = lib.strings.concatStringsSep "\n" (
        builtins.map (command: "${builtins.toString command}") cfg.sessionStartup
      );

      # NOTE: nushell only accepts \u{1b} for the escape character, but
      # JSON and home-manager's environmentVariables write \u001b
      nushellString = value: builtins.replaceStrings [ "\\u001b" ] [ "\\u{1b}" ] (builtins.toJSON value);
    in
    {
      dot.programs.shell.package = config.programs.nushell.package;

      programs.nushell.enable = true;

      programs.nushell.envFile.text = ''
        ${builtins.readFile ./env.nu}

        ${vars}

        $env.PROMPT_INDICATOR_VI_INSERT = ${nushellString config.dot.prompt.nushellIndicators.insert}
        $env.PROMPT_INDICATOR_VI_NORMAL = ${nushellString config.dot.prompt.nushellIndicators.normal}
      '';

      programs.nushell.configFile.text = ''
        ${builtins.readFile ./config.nu}

        ${aliases}

        ${startup}
      '';

      home.packages = [ pkgs.nufmt ];

      programs.helix.languages = {
        language-server.nu-lsp = {
          command = lib.getExe config.programs.nushell.package;
          args = [ "--lsp" ];
        };

        language = [
          {
            name = "nu";
            language-servers = [ "nu-lsp" ];
            formatter = {
              command = "${lib.getExe pkgs.nufmt} --stdin";
            };
            auto-format = true;
          }
        ];
      };

      home.shell.enableNushellIntegration = true;
    };
}
