{
  self.lib.deprecated.homeModules.mako =
    {
      lib,
      osConfig,
      pkgs,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;
    in
    lib.mkIf (hardware.graphics && hardware.wayland) {
      services.mako.enable = true;
      services.mako.settings = {
        width = 512;
        height = 256;
        outer-margin = 32;
        margin = 8;
        padding = 8;
        border-size = 2;
        border-radius = 4;
        icons = 1;
        max-icon-size = 128;
        default-timeout = 10000;
        anchor = "bottom-right";
      };

      home.activation = {
        makoReloadAction = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          ${pkgs.mako}/bin/makoctl reload || true
        '';
      };
    };
}
