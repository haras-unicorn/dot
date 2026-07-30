{
  machines.homeModules.mommy =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      package = pkgs.mommy.override {
        mommySettings = {
          caregiver = "daddy";
          pronouns = "he him his his himself";
        };
      };
    in
    {
      options.dot = {
        mommy = lib.mkEnableOption "mommy" // {
          default = true;
        };
      };

      config = lib.mkIf config.dot.mommy {
        home.packages = [
          package
        ];

        programs.nushell.extraConfig = lib.mkAfter ''
          let last_command_prompt = $env.PROMPT_COMMAND_RIGHT
          let mommy_command_prompt = { || ${lib.getExe package} -1 -s $env.LAST_EXIT_CODE }
          $env.PROMPT_COMMAND_RIGHT = $mommy_command_prompt
          def --env "enable mommy" [] {
            $env.PROMPT_COMMAND_RIGHT = $mommy_command_prompt
          }
          def --env "disable mommy" [] {
            $env.PROMPT_COMMAND_RIGHT = $last_command_prompt
          }
        '';
      };
    };
}
