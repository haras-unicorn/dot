{ pkgs, ... }:

{
  home.shared = {
    home.packages = [
      pkgs.zed-editor
    ];

    xdg.configFile."zed/settings.json".text =
      builtins.readFile ./settings.json;
  };
}
