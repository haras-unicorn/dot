{
  machines.homeModules.nemo =
    {
      pkgs,
      lib,
      osConfig,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;

      package = pkgs.nemo;
    in
    lib.mkIf hardware.browser {
      dot.programs.files.package = package;

      dot.desktop.windowrules = [
        {
          rule = "float";
          selector = "class";
          arg = "nemo";
        }
      ];

      home.packages = [ package ];
    };
}
