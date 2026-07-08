{
  self.lib.deprecated.homeModules.pcmanfm =
    {
      pkgs,
      lib,
      osConfig,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;

      package = pkgs.pcmanfm;
    in
    lib.mkIf hardware.browser {
      dot.programs.files.package = package;

      dot.desktop.windowrules = [
        {
          rule = "float";
          selector = "class";
          arg = "pcmanfm";
        }
      ];

      home.packages = [ package ];
    };
}
