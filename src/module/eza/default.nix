{ pkgs, config, ... }:

{
  shared = {
    dot = {
      shell.aliases = {
        la = "${pkgs.eza}/bin/eza ${pkgs.lib.escapeShellArgs config.programs.eza.extraOptions}";
        tree = "${pkgs.eza}/bin/eza ${pkgs.lib.escapeShellArgs config.programs.eza.extraOptions} --tree";
      };
    };
  };

  home = {
    programs.eza.enable = true;
    programs.eza.extraOptions = [
      "--all"
      "--long"
      "--color=always"
      "--group-directories-first"
      "--icons"
      "--group"
      "--header"
      "--icons"
      "--git"
    ];
  };
}
