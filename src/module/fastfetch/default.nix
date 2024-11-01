{ pkgs, ... }:

# TODO: looks ugly

{
  home = {
    shell.sessionStartup = [
      "${pkgs.fastfetch}/bin/fastfetch"
    ];

    xdg.configFile."fastfetch/config.jsonc".source = ./fastfetch.json;

    home.packages = with pkgs; [
      fastfetch
    ];
  };
}
