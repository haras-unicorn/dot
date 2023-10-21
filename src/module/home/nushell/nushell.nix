{ ... }:

{
  programs.nushell.enable = true;

  programs.nushell.environmentVariables = {
    PROMPT_INDICATOR_VI_INSERT = "'󰞷 '";
    PROMPT_INDICATOR_VI_NORMAL = "' '";
  };

  programs.nushell.shellAliases = {
    pls = "sudo";
    rm = "rm -i";
    mv = "mv -i";
    yas = "yes";
  };

  programs.nushell.configFile.source = ./config.nu;
}
