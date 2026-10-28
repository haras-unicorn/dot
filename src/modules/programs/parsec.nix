{
  self.nixpkgs.config.allowUnfreePackageNames = [ "parsec-bin" ];

  self.homeModules.parsec.value =
    {
      pkgs,
      lib,
      osConfig,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;
    in
    lib.mkIf hardware.browser {
      home.packages = [
        pkgs.parsec-bin
      ];
    };
}
