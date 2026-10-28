{
  self.homeModules.zenity.value =
    {
      lib,
      osConfig,
      pkgs,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;

      package = pkgs.zenity;
    in
    lib.mkIf hardware.graphics {
      dot.desktop.windowrules = [
        {
          rule = "float";
          selector = "class";
          arg = "zenity";
        }
      ];

      home.packages = [
        package
      ];
    };
}
