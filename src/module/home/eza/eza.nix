{ pkgs, config, ... }:

{
  programs.nushell.shellAliases = {
    la = "${pkgs.eza}/bin/eza";
    tree = "${pkgs.eza}/bin/eza --tree";
  };

  programs.eza.enable = true;

  programs.nushell.shellAliases = {
    eza = "${pkgs.eza}/bin/eza ${pkgs.lib.escapeShellArgs config.programs.eza.extraOptions}";
  };

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
