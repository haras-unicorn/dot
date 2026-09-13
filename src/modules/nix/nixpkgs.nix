{ inputs, ... }:

{
  self.nixosModules.nixpkgs.value =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      hardware = config.dot.hardware;
    in
    {
      nixpkgs.config = {
        cudaSupport = hardware.cuda;
        rocmSupport = hardware.rocm;
      };

      _module.args.unstablePkgs = import inputs.nixpkgs-unstable {
        inherit (config.nixpkgs) system config overlays;
      };
    };

  self.homeModules.nixpkgs.value = { osConfig, ... }: {
    _module.args.unstablePkgs = osConfig._module.args.unstablePkgs;
  };
}
