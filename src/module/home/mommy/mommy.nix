{ pkgs, config, ... }:

{
  home.packages = with pkgs; [
    mommy
  ];

  # TODO: better starship integration - this makes sure mommy is set after starship sets its things
  programs.nushell.extraConfig = ''
    source "${config.xdg.configHome}/nushell/config.nu"
    $env.PROMPT_COMMAND_RIGHT = { || ${pkgs.mommy}/bin/mommy -1 -s $env.LAST_EXIT_CODE }
    exit 0
  '';
}
