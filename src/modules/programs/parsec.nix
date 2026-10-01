{
  machines.nixosModules.ollama-openwebui =
    { lib, config, ... }:
    let
      hardware = config.dot.hardware;
    in
    lib.mkIf hardware.browser {
      dot.nixpkgs.allowUnfreePackageNames = [ "parsec-bin" ];
    };

  machines.homeModules.parsec =
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
