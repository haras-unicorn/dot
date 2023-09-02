{}:

{
  home.shellAliases = {
    grep = "rg";
  };

  programs.ripgrep.enable = true;
  programs.ripgrep.arguments = [
    "--max-columns=100"
    "--max-columns-preview"
    "--colors=auto"
    "--smart-case"
  ];
}
