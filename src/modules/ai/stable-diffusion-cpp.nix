{
  machines.homeModules.stable-diffusion-cpp =
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
        pkgs.stable-diffusion-cpp
      ];
    };
}
