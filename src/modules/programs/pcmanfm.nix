{
  machines.nixosModules.pcmanfm =
    {
      lib,
      config,
      ...
    }:
    let
      hardware = config.dot.hardware;
    in
    lib.mkIf hardware.graphics {
      services.gvfs.enable = true;
    };

  machines.homeModules.pcmanfm =
    {
      pkgs,
      lib,
      osConfig,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;

      mime = {
        "inode/directory" = "${pkgs.pcmanfm}/share/applications/pcmanfm.desktop";
      };
    in
    lib.mkIf hardware.interface {
      dot.desktop.windowrules = [
        {
          rule = "float";
          selector = "class";
          arg = "pcmanfm";
        }
      ];

      home.packages = [ pkgs.pcmanfm ];

      xdg.mimeApps.associations.added = mime;
      xdg.mimeApps.defaultApplications = mime;
    };
}
