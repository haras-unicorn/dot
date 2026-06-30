{
  self.lib.deprecated.homeModules.picom =
    {
      config,
      osConfig,
      lib,
      pkgs,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;

      colors = config.lib.stylix.colors.withHashtag;
    in
    lib.mkIf (hardware.graphics && !hardware.wayland) {
      home.activation = {
        picomReloadAction = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          ${pkgs.procps}/bin/pkill --signal "SIGUSR1" "picom" || true
        '';
      };

      services.picom.enable = true;
      services.picom.settings = lib.mkForce { };

      xdg.configFile."picom/picom.conf".text = ''
        ${builtins.readFile ./picom.conf}

        shadow-color = "${colors.base00}";
      '';
    };
}
