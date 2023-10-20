{ pkgs, ... }:

{
  programs.nushell.shellAliases = {
    la = "${pkgs.eza}/bin/eza";
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
  ];
}
