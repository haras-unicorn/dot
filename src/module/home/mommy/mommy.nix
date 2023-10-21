{ pkgs, ... }:

{
  home.packages = with pkgs; [
    mommy
  ];

  # TODO: somehow make sure this gets added in after starship?
  programs.nushell.extraConfig = ''
    $env.PROMPT_COMMAND_RIGHT = { || ${pkgs.mommy}/bin/mommy -1 -s $env.LAST_EXIT_CODE }
  '';
}
