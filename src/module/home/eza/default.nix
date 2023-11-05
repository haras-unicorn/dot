{ pkgs, config, ... }:

{
  home.shellAliases = {
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
}
