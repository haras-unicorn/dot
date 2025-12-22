{
  pkgs,
  config,
  lib,
  ...
}:

let
  enable = config.dot.mommy.enable;
in
{
  homeManagerModule = {
    options.dot = {
      mommy.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
    };

    config = lib.mkIf enable {
      home.packages = [
        pkgs.mommy
      ];

      programs.nushell.extraConfig = lib.mkAfter ''
        let last_command_prompt = $env.PROMPT_COMMAND_RIGHT
        $env.PROMPT_COMMAND_RIGHT = { || ${pkgs.mommy}/bin/mommy -1 -s $env.LAST_EXIT_CODE }
        def --env "enable mommy" [] {
          $env.PROMPT_COMMAND_RIGHT = { || ${pkgs.mommy}/bin/mommy -1 -s $env.LAST_EXIT_CODE }
        }
        def --env "disable mommy" [] {
          $env.PROMPT_COMMAND_RIGHT = $last_command_prompt
        }
      '';
    };
  };
}
