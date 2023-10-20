{ pkgs, config, ... }:

{
  home.packages = with pkgs; [
    fastfetch
    mommy
  ];

  programs.direnv.enable = true;
  programs.direnv.enableNushellIntegration = true;
  programs.direnv.nix-direnv.enable = true;

  programs.nushell.enable = true;

  programs.nushell.extraEnv = ''
    $env.PATH = $"${config.home.homeDirectory}/bin:($env.PATH)"
    $env.PATH = $"bin:($env.PATH)"

    $env.PROMPT_COMMAND_RIGHT = {|| mommy -1 -s $env.LAST_EXIT_CODE }
  '';
  programs.nushell.extraConfig = ''
    $env.config = {
      show_banner: false

      edit_mode: vi
      cursor_shape: {
        vi_insert: line
        vi_normal: underscore
      }

      hooks: {
        env_change: {
          PWD: { || direnv export json | from json | default {} | load-env }
        }
      }

      table: {
        mode: with_love
      }
    }

    alias pls = sudo;
    alias rm = rm -i;
    alias mv = mv -i;
    alias yas = yes;

    # fastfetch
  '';
  programs.nushell.environmentVariables = {
    PROMPT_INDICATOR_VI_INSERT = "'󰞷 '";
    PROMPT_INDICATOR_VI_NORMAL = "' '";
  };

  programs.starship.enableNushellIntegration = true;
  programs.zoxide.enableNushellIntegration = true;

  xdg.configFile."fastfetch/config.jsonc".source = ./fastfetch.json;
}
