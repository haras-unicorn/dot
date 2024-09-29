{ config, ... }:

let
  bootstrap = config.dot.colors.bootstrap;
in
{
  home.shared = {
    programs.starship.enable = true;
    programs.starship.enableBashIntegration = true;
    programs.starship.enableNushellIntegration = true;

    programs.starship.settings = builtins.fromTOML ''
      # TODO: fix how slow python is
      # $python\
      format = """\
      [╭─](bold fg:${bootstrap.accent.hex})\

      $username[@](bold fg:${bootstrap.accent.hex})$hostname\
      [\\(](bold fg:${bootstrap.accent.hex})\
      $localip\
      [\\)](bold fg:${bootstrap.accent.hex}) \

      [using](italic fg:${bootstrap.textAlternate.hex}) $shlvl$shell \
      [\\(](bold fg:${bootstrap.accent.hex}) \
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
      [\\)](bold fg:${bootstrap.accent.hex}) \

      $jobs\
      $time\
      $cmd_duration\
      $status\

      $battery\
      $memory_usage\

      $line_break\

      [│](bold fg:${bootstrap.accent.hex}) \

      [in](italic fg:${bootstrap.textAlternate.hex}) $directory\

      $package\
      [\\[](bold fg:${bootstrap.accent.hex}) \
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
      [\\]](bold fg:${bootstrap.accent.hex}) \

      $git_branch$hg_branch\
      $git_commit$git_state$git_metrics$git_status\

      $line_break\

      [╰─](bold fg:${bootstrap.accent.hex})\
      """

      scan_timeout = 1000
      command_timeout = 3000
      add_newline = true

      [username]
      format = "[$user]($style)"
      style_user = "bold fg:${bootstrap.primary.hex}"
      style_root = "bold fg:${bootstrap.warning.hex}"
      show_always = true

      [hostname]
      format = "[$hostname]($style)"
      style = "bold fg:${bootstrap.secondary.hex}"
      trim_at = "-"
      ssh_only = false
      disabled = false

      [localip]
      format = "[$localipv4]($style)"
      style = "bold fg:${bootstrap.secondary.hex}"
      disabled = false

      [shell]
      format = "[$indicator]($style)"
      fish_indicator = "󰈺 "
      bash_indicator = " "
      style = "bold fg:${config.dot.colors.terminal.blue.hex}"
      disabled = false

      [shlvl]
      threshold = 2
      format = "[$symbol]($style)"
      symbol = ""
      repeat = true
      style = "bold fg:${bootstrap.text.hex}"
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
      format = "[at](italic fg:${bootstrap.textAlternate.hex}) [$time]($style) "
      style = "bold fg:${bootstrap.info.hex}"
      disabled = false

      [cmd_duration]
      min_time = 1
      format = "[took](italic fg:${bootstrap.textAlternate.hex}) [$duration]($style)"
      disabled = false
      style = "underline bold fg:${bootstrap.info.hex}"

      [status]
      symbol = " "
      style = "fg:${bootstrap.danger.hex}"
      format = """ \
      [[{](bold fg:${bootstrap.accent.hex})\
      $symbol\
      $status_common_meaning\
      $status_signal_name\
      $status_maybe_int\
      [}](bold fg:${bootstrap.accent.hex})]\
      ($style)"""
      map_symbol = true
      disabled = false

      [package]
      symbol = "󰏗 "
      format = "[$symbol$version]($style) "

      [directory]
      style = "bold fg:${bootstrap.textAlternate.hex}"
      read_only = " "
      truncation_length = 3
      truncate_to_repo = true

      [git_branch]
      format = "[on](italic fg:${bootstrap.textAlternate.hex}) [$symbol $branch]($style)"
      style = "bold fg:${bootstrap.info.hex}"
      symbol = ""

      [hg_branch]
      format = "[on](italic fg:${bootstrap.textAlternate.hex}) [$symbol $branch]($style)"
      style = "bold fg:${bootstrap.info.hex}"
      symbol = ""

      [git_status]
      style = "bold fg:${bootstrap.warning.hex}"
      format = """ \
      [[{](bold fg:${bootstrap.accent.hex})\
      $all_status\
      $ahead_behind\
      [}](bold fg:${bootstrap.accent.hex})]\
      ($style)"""
      ahead = "$${count}"
      diverged = "󰹺$${ahead_count}$${behind_count}"
      behind = "$${count}"
      deleted = "x"

      [character]
      success_symbol = "[󰞷](bold fg:${bootstrap.success.hex})"
      vicmd_symbol = "[ ](bold fg:${bootstrap.success.hex})"
      error_symbol = "[ ](bold fg:${bootstrap.danger.hex})"

      [battery]
      format = " [$symbol$percentage]($style)"

      [[battery.display]]
      threshold = 20
    '';
  };
}
