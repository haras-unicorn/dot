{
  machines.homeModules.mistral-rs =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      cuda = config.nixpkgs.config.cudaSupport;
    in
    lib.mkIf cuda {
      home.packages = [
        pkgs.mistral-rs
      ];
    };
}
