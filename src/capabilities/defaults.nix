{ ... }:

{
  flake.homeModules.capabilities-defaults =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    {
      options.dot = {
        shell = {
          package = lib.mkOption {
            type = lib.types.package;
            description = ''Default shell package'';
          };
          bin = lib.mkOption {
            type = lib.types.str;
            description = ''Default shell package binary'';
          };
          sessionVariables = lib.mkOption {
            type =
              with lib.types;
              lazyAttrsOf (oneOf [
                str
                path
                int
                float
              ]);
            default = { };
            description = ''
              Environment variables to set on session start with Nushell.
            '';
          };
          aliases = lib.mkOption {
            type = with lib.types; lazyAttrsOf str;
            default = { };
            description = ''
              Aliases to use in default shell.
            '';
          };
          sessionStartup = lib.mkOption {
            type = with lib.types; listOf str;
            default = [ ];
            description = ''
              Commands to execute on session start with default shell.
            '';
          };
          copy = lib.mkOption {
            type = lib.types.package;
            description = ''
              Copy command.
            '';
          };
          paste = lib.mkOption {
            type = lib.types.package;
            description = ''
              Paste command.
            '';
          };
          type = lib.mkOption {
            type = lib.types.package;
            description = ''
              Type command.
            '';
          };
          screenshot = lib.mkOption {
            type = lib.types.package;
            description = ''
              Screenshot command.
            '';
          };
          regionshot = lib.mkOption {
            type = lib.types.package;
            description = ''
              Region screenshot command.
            '';
          };
        };
        editor = {
          package = lib.mkOption {
            type = lib.types.package;
            description = ''
              Default editor package.
            '';
          };
          bin = lib.mkOption {
            type = lib.types.str;
            description = ''
              Default editor package binary.
            '';
          };
        };
        terminal = {
          package = lib.mkOption {
            type = lib.types.package;
            description = ''
              Default terminal package.
            '';
          };
          bin = lib.mkOption {
            type = lib.types.str;
            description = ''
              Default terminal package binary.
            '';
          };
          sessionVariables = lib.mkOption {
            type =
              with lib.types;
              lazyAttrsOf (oneOf [
                str
                path
                int
                float
              ]);
            default = { };
            description = ''
              Environment variables to set on default terminal startup.
            '';
          };
        };
        visual = {
          package = lib.mkOption {
            type = lib.types.package;
            description = ''
              Default visual editor package.
            '';
          };
          bin = lib.mkOption {
            type = lib.types.str;
            description = ''
              Default visual editor package binary.
            '';
          };
        };
        browser = {
          package = lib.mkOption {
            type = lib.types.package;
            description = ''
              Default browser package.
            '';
          };
          bin = lib.mkOption {
            type = lib.types.str;
            description = ''
              Default browser package binary.
            '';
          };
        };
        pinentry = {
          package = lib.mkOption {
            type = lib.types.package;
            description = ''
              Default pinentry package.
            '';
          };
          bin = lib.mkOption {
            type = lib.types.str;
            description = ''
              Default pinentry package binary.
            '';
          };
        };
      };
    };
}
