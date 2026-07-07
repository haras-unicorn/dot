{
  self.lib.deprecated.homeModules.wofi =
    {
      pkgs,
      lib,
      config,
      osConfig,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;

      wofiDmenu = pkgs.writeShellApplication {
        name = "wofi-dmenu";
        runtimeInputs = [ pkgs.wofi ];
        text = ''
          exec wofi --dmenu --prompt select "$@"
        '';
      };

      wofiLauncher = pkgs.writeShellApplication {
        name = "wofi-launcher";
        runtimeInputs = [ pkgs.wofi ];
        text = ''
          exec wofi --dmenu --show drun --prompt run "$@"
        '';
      };
    in
    lib.mkIf (hardware.visual && hardware.wayland) {
      dot.programs.shell.dmenu = lib.mkDefault wofiDmenu;
      dot.programs.shell.launcher = lib.mkDefault wofiLauncher;

      programs.wofi.enable = true;

      programs.wofi.settings = {
        allow_markup = true;
      };
    };
}
