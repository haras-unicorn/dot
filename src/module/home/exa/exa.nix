{ ... }:

{
  # home.shellAliases = {
  #   la = "exa";
  # };
  programs.nushell.extraEnv = ''
    alias la = exa;
  '';

  programs.exa.enable = true;
  programs.exa.extraOptions = [
    "--all"
    "--list"
    "--color=always"
    "--group-directories-first"
    "--icons"
    "--group"
    "--header"
  ];
}
