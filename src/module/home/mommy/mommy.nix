{ pkgs, ... }:

{
  home.packages = with pkgs; [
    mommy
  ];

  # TODO: fix
  programs.nushell.loginFile.text = ''
    $env.PROMPT_COMMAND_RIGHT = { || ${pkgs.mommy}/bin/mommy -1 -s $env.LAST_EXIT_CODE }
  '';
}
