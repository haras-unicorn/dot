{ pkgs, ... }:

{
  home.packages = with pkgs; [
    fastfetch
    mommy
  ];

  programs.direnv.enable = true;
  programs.direnv.enableNushellIntegration = true;
  programs.direnv.nix-direnv.enable = true;

  programs.nushell.enable = true;

  programs.nushell.environmentVariables = {
    PROMPT_INDICATOR_VI_INSERT = "'󰞷 '";
    PROMPT_INDICATOR_VI_NORMAL = "' '";
    PROMPT_COMMAND_RIGHT = "{ || mommy -1 -s $env.LAST_EXIT_CODE }";
  };

  programs.nushell.extraConfig = builtins.readFile ./config.nu;

  programs.starship.enableNushellIntegration = true;
  programs.zoxide.enableNushellIntegration = true;

  xdg.configFile."fastfetch/config.jsonc".source = ./fastfetch.json;
}
