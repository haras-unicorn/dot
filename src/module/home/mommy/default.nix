{ pkgs, ... }:

# TODO: doesn't work

{
  home.packages = with pkgs; [
    mommy
  ];

  # NOTE: somehow make sure this gets added in after starship?
  programs.nushell.environmentVariables = {
    PROMPT_COMMAND_RIGHT = "{ || ${pkgs.mommy}/bin/mommy -1 -s $env.LAST_EXIT_CODE }";
  };
}
