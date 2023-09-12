{ ... }:

{
  programs.nushell.extraEnv = ''
    alias la = exa;
  '';

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
