{ pkgs, config, ... }:

let
  mako-walapp = pkgs.writeShellApplication {
    name = "makore";
    text = ''
      ${config.services.mako.package}/bin/makoctl reload || true
    '';
  };
in
{
  home.packages = with pkgs; [
    libnotify
  ];

  services.mako.enable = true;

  xdg.configFile."walapp/mako".source = "${mako-walapp}/bin/mako-walapp";
  xdg.configFile."walapp/mako".executable = true;

  xdg.configFile."mako/config".enable = false;
  programs.lulezojne.config.plop = [
    {
      template = ''
        font="JetBrainsMono" 16
        background-color={{ hexa (set-alpha ansi.main.black 0.5) }}
        text-color={{ hex ansi.main.white }}
        border-color={{ hex ansi.main.yellow }}
        progress-color={{ hex ansi.main.green }}
      '';
      "in" = "${config.xdg.configHome}/mako/config";
      "then" = "${mako-walapp}/bin/mako-walapp";
    }
  ];
}
