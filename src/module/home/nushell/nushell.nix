{ pkgs, config, ... }:

{
  home.packages = with pkgs; [
    fastfetch
    mommy
    vivid
  ];

  programs.nushell.enable = true;

  programs.nushell.environmentVariables = {
    PROMPT_INDICATOR_VI_INSERT = "'󰞷 '";
    PROMPT_INDICATOR_VI_NORMAL = "' '";
    PROMPT_COMMAND_RIGHT = "{ || ${pkgs.mommy}/bin/mommy -1 -s $env.LAST_EXIT_CODE }";
  };

  programs.nushell.shellAliases = {
    pls = "sudo";
    rm = "rm -i";
    mv = "mv -i";
    yas = "yes";
  };

  programs.nushell.configFile.source = ./config.nu;

  programs.direnv.enable = true;
  programs.direnv.enableNushellIntegration = true;
  programs.direnv.nix-direnv.enable = true;

  programs.starship.enableNushellIntegration = true;
  programs.zoxide.enableNushellIntegration = true;

  xdg.configFile."fastfetch/config.jsonc".source = ./fastfetch.json;

  programs.lulezojne.config.plop = [
    {
      template = builtins.readFile ./ls-colors.yml.hbs;
      "in" = "${config.xdg.configHome}/vivid/themes/lulezojne.yml";
      "then" = {
        command = "echo";
        args = [ "Ye!" ];
      };
    }
  ];
}
