{
  self.lib.deprecated.homeModules.rofi =
    {
      pkgs,
      lib,
      config,
      osConfig,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;

      rofiDmenu = pkgs.writeShellApplication {
        name = "rofi-dmenu";
        runtimeInputs = [ pkgs.rofi ];
        text = ''
          exec rofi -dmenu -config ${./keepmenu.rasi} "$@"
        '';
      };

      rofiLauncher = pkgs.writeShellApplication {
        name = "rofi-launcher";
        runtimeInputs = [ pkgs.rofi ];
        text = ''
          exec rofi -show drun -modi run,drun,window -config ${./launcher.rasi} "$@"
        '';
      };
    in
    lib.mkIf (hardware.visual && !hardware.wayland) {
      dot.programs.shell.dmenu = lib.mkDefault rofiDmenu;
      dot.programs.shell.launcher = lib.mkDefault rofiLauncher;

      programs.rofi.enable = true;
      xdg.configFile."rofi/launcher.rasi".source = ./launcher.rasi;
      xdg.configFile."rofi/colors.rasi".source = ./colors.rasi;
      xdg.configFile."rofi/keepmenu.rasi".source = ./keepmenu.rasi;
    };
}
