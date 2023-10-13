{ pkgs, config, ... }:

{
  home.packages = with pkgs; [
    fastfetch
  ];

  programs.direnv.enable = true;
  programs.direnv.enableNushellIntegration = true;
  programs.direnv.nix-direnv.enable = true;

  programs.nushell.enable = true;

  programs.nushell.extraEnv = ''
    $env.PATH = $"${config.home.homeDirectory}/bin:($env.PATH)"
    $env.PATH = $"bin:($env.PATH)"

    alias pls = sudo;
    alias rm = rm -i;
    alias mv = mv -i;
    alias yas = yes;
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
        pre_prompt: [{ ||
          let direnv = (direnv export json | from json | default {})
          if ($direnv | is-empty) {
              return
          }
          $direnv
          | items {|key, value|
             {
                key: $key
                value: (if $key in $env.ENV_CONVERSIONS {
                  do ($env.ENV_CONVERSIONS | get $key | get from_string) $value
                } else {
                    $value
                })
              }
          } | transpose -ird | load-env
        }]      
      }
    }

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
