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
        "inode/directory" = "dot-pcmanfm.desktop";
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

      xdg.desktopEntries.dot-pcmanfm = {
        name = "PCManFM";
        exec = "${lib.getExe pkgs.pcmanfm} %U";
        terminal = false;
        mimeType = [
          "inode/directory"
        ];
        noDisplay = true;
      };

      xdg.mimeApps.associations.added = mime;
      xdg.mimeApps.defaultApplications = mime;
    };
}
