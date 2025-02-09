{ pkgs, config, lib, ... }:

let
  colors = config.lib.stylix.colors.withHashtag;
  nsfw = config.dot.prompt.nsfw;
in
{
  options = {
    prompt.nsfw = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
  };

  home = {
    home.packages = [
      pkgs.mommy
    ];

    programs.nushell.extraConfig = lib.mkIf nsfw (lib.mkAfter ''
      let last_command_prompt = $env.PROMPT_COMMAND_RIGHT
      $env.PROMPT_COMMAND_RIGHT = { || ${pkgs.mommy}/bin/mommy -1 -s $env.LAST_EXIT_CODE }
      def --env "enable mommy" [] {
        $env.PROMPT_COMMAND_RIGHT = { || ${pkgs.mommy}/bin/mommy -1 -s $env.LAST_EXIT_CODE }
      }
      def --env "disable mommy" [] {
        $env.PROMPT_COMMAND_RIGHT = $last_command_prompt
      }
    '');

    programs.starship.enable = true;

    programs.starship.settings = builtins.fromTOML ''
      # TODO: fix how slow python is
      # $python\
      format = """\
      [╭─](bold fg:${colors.cyan})\

      $username[@](bold fg:${colors.cyan})$hostname\
      [\\(](bold fg:${colors.cyan})\
      $localip\
      [\\)](bold fg:${colors.cyan}) \

      [using](italic fg:${colors.base00}) $shlvl$shell \
      [\\(](bold fg:${colors.cyan}) \
      $aws\
      $azure\
      $gcloud\
      $openstack\
      $singularity\
      $container\
      $docker_context\
      $kubernetes\
      $terraform\
      $nix_shell\
      $conda\
      [\\)](bold fg:${colors.cyan}) \

      $jobs\
      $time\
      $cmd_duration\
      $status\

      $battery\
      $memory_usage\

      $line_break\

      [│](bold fg:${colors.cyan}) \

      [in](italic fg:${colors.base00}) $directory\

      $package\
      [\\[](bold fg:${colors.cyan}) \
      $helm\
      $cmake\
      $cobol\
      $dart\
      $deno\
      $dotnet\
      $elixir\
      $elm\
      $erlang\
      $golang\
      $java\
      $julia\
      $kotlin\
      $lua\
      $nim\
      $nodejs\
      $ocaml\
      $perl\
      $php\
      $purescript\
      $rlang\
      $red\
      $ruby\
      $rust\
      $scala\
      $swift\
      $vlang\
      $vagrant\
      $zig\
      $crystal\
      [\\]](bold fg:${colors.cyan}) \

      $git_branch$hg_branch\
      $git_commit$git_state$git_metrics$git_status\

      $line_break\

      [╰─](bold fg:${colors.cyan})\
      """

      scan_timeout = 1000
      command_timeout = 3000
      add_newline = true

      [username]
      format = "[$user]($style)"
      style_user = "bold fg:${colors.magenta}"
      style_root = "bold fg:${colors.yellow}"
      show_always = true

      [hostname]
      format = "[$hostname]($style)"
      style = "bold fg:${colors.magenta}"
      trim_at = "-"
      ssh_only = false
      disabled = false

      [localip]
      format = "[$localipv4]($style)"
      style = "bold fg:${colors.magenta}"
      disabled = false

      [shell]
      format = "[$indicator]($style)"
      fish_indicator = "󰈺 "
      bash_indicator = " "
      style = "bold fg:${colors.blue}"
      disabled = false

      [shlvl]
      threshold = 2
      format = "[$symbol]($style)"
      symbol = ""
      repeat = true
      style = "bold fg:${colors.base00}"
      disabled = false

      [aws]
      format = "[$symbol($profile )(\\($region\\) )(\\[$duration\\])]($style) "
      symbol = " "

      [azure]
      format = "[$symbol($subscription)]($style) "
      symbol = " "

      [conda]
      format = "[$symbol$environment]($style) "
      symbol = " "

      [dart]
      format = "[$symbol($version)]($style) "
      symbol = " "

      [docker_context]
      format = "[$symbol$context]($style) "
      symbol = " "

      [container]
      format = "[$symbol \\[$name\\]]($style) "
      symbol = " "

      [elixir]
      format = "[$symbol($version \\(OTP $otp_version\\))]($style) "
      symbol = " "

      [elm]
      format = "[$symbol($version)]($style) "
      symbol = " "

      [golang]
      format = "[$symbol($version)]($style) "
      symbol = " "

      [java]
      format = "[$symbol($version)]($style) "
      symbol = " "

      [julia]
      format = "[$symbol($version)]($style) "
      symbol = " "

      [nim]
      format = "[$symbol($version)]($style) "
      symbol = " "

      [nix_shell]
      format = "[$symbol$state( \\($name\\))]($style) "
      symbol = " "

      [nodejs]
      format = "[$symbol($version)]($style) "
      symbol = " "

      [perl]
      format = "[$symbol($version)]($style) "
      symbol = " "

      [php]
      format = "[$symbol($version)]($style)"
      symbol = " "

      [python]
      format = "[$${symbol}$${pyenv_prefix}($${version})(\\($virtualenv\\))]($style) "
      symbol = " "

      [ruby]
      format = "[$symbol($version)]($style) "
      symbol = " "

      [rust]
      format = "[$symbol($version)]($style) "
      symbol = " "

      [swift]
      format = "[$symbol($version)]($style) "
      symbol = "ﯣ "

      [cmake]
      format = "[$symbol($version)]($style) "
      symbol = " "

      [lua]
      format = "[$symbol($version)]($style) "
      symbol = " "

      [dotnet]
      format = "[$symbol($version)(🎯 $tfm)]($style) "
      symbol = " "

      [time]
      format = "[at](italic fg:${colors.base00}) [$time]($style) "
      style = "bold fg:${colors.blue}"
      disabled = false

      [cmd_duration]
      min_time = 1
      format = "[took](italic fg:${colors.base00}) [$duration]($style)"
      disabled = false
      style = "underline bold fg:${colors.blue}"

      [status]
      symbol = " "
      style = "fg:${colors.red}"
      format = """ \
      [[{](bold fg:${colors.cyan})\
      $symbol\
      $status_common_meaning\
      $status_signal_name\
      $status_maybe_int\
      [}](bold fg:${colors.cyan})]\
      ($style)"""
      map_symbol = true
      disabled = false

      [package]
      symbol = "󰏗 "
      format = "[$symbol$version]($style) "

      [directory]
      style = "bold fg:${colors.base00}"
      read_only = " "
      truncation_length = 3
      truncate_to_repo = true

      [git_branch]
      format = "[on](italic fg:${colors.base00}) [$symbol $branch]($style)"
      style = "bold fg:${colors.blue}"
      symbol = ""

      [hg_branch]
      format = "[on](italic fg:${colors.base00}) [$symbol $branch]($style)"
      style = "bold fg:${colors.blue}"
      symbol = ""

      [git_status]
      style = "bold fg:${colors.yellow}"
      format = """ \
      [[{](bold fg:${colors.cyan})\
      $all_status\
      $ahead_behind\
      [}](bold fg:${colors.cyan})]\
      ($style)"""
      ahead = "''${count}"
      diverged = "󰹺''${ahead_count}''${behind_count}"
      behind = "''${count}"
      deleted = "x"

      [character]
      success_symbol = "[󰞷](bold fg:${colors.green})"
      vicmd_symbol = "[ ](bold fg:${colors.green})"
      error_symbol = "[ ](bold fg:${colors.red})"

      [battery]
      format = " [$symbol$percentage]($style)"

      [[battery.display]]
      threshold = 20
    '';
  };
}
