{ ... }:

{
  programs.nushell.enable = true;

  programs.nushell.environmentVariables = {
    PROMPT_INDICATOR_VI_INSERT = "'󰞷 '";
    PROMPT_INDICATOR_VI_NORMAL = "' '";
  };

  programs.nushell.configFile.source = ./config.nu;
}
