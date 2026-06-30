{
  machines.homeModules.whisper =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cuda = config.nixpkgs.config.cudaSupport;
    in
    lib.mkIf cuda {
      home.packages = [
        pkgs.whisper-cpp
      ];
    };
}
