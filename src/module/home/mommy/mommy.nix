{ pkgs, ... }:

{
  home.packages = with pkgs; [
    mommy
  ];

  programs.nushell.extraConfig = ''
    $env.PROMPT_COMMAND_RIGHT = { || ${pkgs.mommy}/bin/mommy -1 -s $env.LAST_EXIT_CODE }
  '';
}
