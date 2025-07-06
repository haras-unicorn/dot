{ pkgs, lib, config, ... }:

# FIXME: completions

# TODO: uncomment formatter when it gets better
# TODO: command_not_found hook with nix run or nix search

let
  cfg = config.dot.shell;

  vars = lib.strings.concatStringsSep
    "\n"
    (builtins.map
      (name: ''$env.${name} = $"(${builtins.toString cfg.sessionVariables."${name}"})"'')
      (builtins.attrNames cfg.sessionVariables));

  aliases = lib.strings.concatStringsSep
    "\n"
    (builtins.map
      (name: ''alias ${name} = ${builtins.toString cfg.aliases."${name}"}'')
      (builtins.attrNames cfg.aliases));

  startup = lib.strings.concatStringsSep
    "\n"
    (builtins.map
      (command: "${builtins.toString command}")
      cfg.sessionStartup);

  # completions = lib.strings.concatStringsSep
  #   "\n"
  #   (builtins.map
  #     (completion: "source ${completion}")
  #     (builtins.filter
  #       ({ completions, ... }: builtins.pathExists completions)
  #       (builtins.map
  #         (name: {
  #           inherit name;
  #           completions = "${pkgs.nu_scripts}/share/nu_scripts/custom-completions/${name}/${name}-completions.nu";
  #         })
  #         (builtins.attrNames
  #           (builtins.readDir "${pkgs.nu_scripts}/share/nu_scripts/custom-completions")))));
in
{
  branch.homeManagerModule.homeManagerModule = {
    dot.shell = { package = pkgs.nushell; bin = "nu"; };

    programs.nushell.enable = true;

    programs.nushell.environmentVariables = {
      PROMPT_INDICATOR_VI_INSERT = "󰞷 ";
      PROMPT_INDICATOR_VI_NORMAL = " ";
    };

    programs.nushell.envFile.text = ''
      ${builtins.readFile ./env.nu}

      ${vars}
    '';

    programs.nushell.configFile.text = ''
      ${builtins.readFile ./config.nu}

      ${aliases}

      ${startup}
    '';

    home.packages = [ pkgs.nufmt ];

    programs.helix.languages = {
      language-server.nu-lsp = {
        command = "${pkgs.nushell}/bin/nu";
        args = [ "--lsp" ];
      };

      language = [{
        name = "nu";
        language-servers = [ "nu-lsp" ];
        # formatter = {
        #   command = "${pkgs.nufmt}/bin/nufmt --stdin";
        # };
        # auto-format = true;
      }];
    };

    programs.direnv.enableNushellIntegration = true;
    programs.zoxide.enableNushellIntegration = true;
    programs.yazi.enableNushellIntegration = true;
    programs.starship.enableNushellIntegration = true;
    programs.carapace.enableNushellIntegration = true;
  };
}
