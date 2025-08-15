{
  pkgs,
  config,
  lib,
  ...
}:

let
  nsfw = config.dot.prompt.nsfw;
in
{
  branch.homeManagerModule.homeManagerModule = {
    options.dot = {
      prompt.nsfw = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
    };

    config = lib.mkIf nsfw {
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
