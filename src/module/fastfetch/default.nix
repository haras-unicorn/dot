{ pkgs, ... }:

# TODO: looks ugly

{
  home.shared = {
    shell.sessionStartup = [
      "${pkgs.fastfetch}/bin/fastfetch"
    ];

    xdg.configFile."fastfetch/config.jsonc".source = ./fastfetch.json;

    home.packages = with pkgs; [
      fastfetch
    ];
  };
}
