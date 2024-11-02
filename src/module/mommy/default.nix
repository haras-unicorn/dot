{ pkgs, ... }:

{
  home = {
    home.packages = with pkgs; [
      mommy
    ];

    programs.nushell.environmentVariables = {
      PROMPT_COMMAND_RIGHT = "{ || ${pkgs.mommy}/bin/mommy -1 -s $env.LAST_EXIT_CODE }";
    };
  };
}
