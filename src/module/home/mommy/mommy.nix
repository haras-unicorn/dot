{ pkgs, ... }:

{
  home.packages = with pkgs; [
    mommy
  ];

  # TODO: better integration with starship
  programs.nushell.environmentVariables = ''
    $env.PROMPT_COMMAND_RIGHT = { || ${pkgs.mommy}/bin/mommy -1 -s $env.LAST_EXIT_CODE }
  '';
}
