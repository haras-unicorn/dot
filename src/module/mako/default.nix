{ pkgs, lib, config, ... }:

let
  bootstrap = config.dot.colors.bootstrap;
in
{
  shared = {
    dot = {
      desktopEnvironment.sessionStartup = [ "${pkgs.mako}/bin/mako" ];
    };
  };

  home.shared = {
    home.packages = with pkgs; [
      libnotify
      mako
    ];

    xdg.configFile."mako/config".text = ''
      font="${config.dot.font.sans.name}" ${builtins.toString config.dot.font.size.large}
      width=512
      height=256

      margin=32
      padding=8
      border-size=2
      border-radius=4
      icons=1
      max-icon-size=128
      default-timeout=10000
      anchor=bottom-right

      background-color=${bootstrap.background}AA
      text-color=${bootstrap.text}
      border-color=${bootstrap.accent}
      progress-color=${bootstrap.success}
    '';


    home.activation = {
      makoReloadAction = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        ${pkgs.mako}/bin/makoctl reload
      '';
    };
  };
}
