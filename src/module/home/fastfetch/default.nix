{ pkgs, ... }:

# TODO: looks ugly

{
  home.packages = with pkgs; [
    fastfetch
  ];

  programs.nushell.extraConfig = ''
    ${pkgs.fastfetch}/bin/fastfetch
  '';

  xdg.configFile."fastfetch/config.jsonc".source = ./fastfetch.json;
}
