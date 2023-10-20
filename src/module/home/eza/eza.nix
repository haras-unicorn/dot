{ pkgs, ... }:

{
  programs.nushell.shellAliases = {
    la = "${pkgs.eza}/bin/eza";
    tree = "${pkgs.eza}/bin/eza --tree";
  };

  programs.eza.enable = true;
  programs.eza.extraOptions = [
    "--all"
    "--list"
    "--color=always"
    "--group-directories-first"
    "--icons"
    "--group"
    "--header"
    "--icons"
    "--git"
  ];
}
