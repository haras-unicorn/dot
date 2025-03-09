{ pkgs, config, ... }:

{
  branch.homeManagerModule.homeManagerModule = {
    shell.aliases = {
      la = "${pkgs.eza}/bin/eza ${pkgs.lib.escapeShellArgs config.programs.eza.extraOptions}";
      tree = "${pkgs.eza}/bin/eza ${pkgs.lib.escapeShellArgs config.programs.eza.extraOptions} --tree";
    };


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
