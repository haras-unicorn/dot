{ pkgs, config, ... }:

{
  home.packages = with pkgs; [
    libnotify
  ];

  services.mako.enable = true;
  xdg.configFile."mako/config" = null;

  programs.lulezojne.config.plop = [
    {
      template = ''
        font="JetBrainsMono" 16
      '';
      "in" = "${config.xdg.configHome}/mako/config";
    }

  ];
}
