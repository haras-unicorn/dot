{
  flake.homeModules.programs-mommy =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.dot = {
        mommy.enable = lib.mkEnableOption "mommy";
      };

      config = lib.mkMerge [
        { dot.mommy.enable = lib.mkDefault true; }
        (lib.mkIf config.dot.mommy.enable {
          home.packages = [
            (pkgs.mommy.override {
              mommySettings = {
                caregiver = "daddy";
                pronouns = "he him his his himself";
              };
            })
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
        })
      ];
    };
}
