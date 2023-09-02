{ ... }:

{
  programs.kitty.enable = true;
  programs.kitty.extraConfig = builtins.readFile ./kitty.conf;
}
