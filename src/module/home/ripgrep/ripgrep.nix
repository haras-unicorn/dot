{ pkgs, ... }:

{
  programs.nushell.shellAliases = {
    grep = "${pkgs.ripgrep}/bin/rg";
  };

  programs.ripgrep.enable = true;
  programs.ripgrep.arguments = [
    "--max-columns=100"
    "--max-columns-preview"
    "--colors=auto"
    "--smart-case"
  ];
}
