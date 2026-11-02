{ inputs, ... }:

{
  self.nixosModules.nixpkgs.value =
    { config, ... }:
    let
      hardware = config.dot.hardware;
    in
    {
      nixpkgs.config = {
        cudaSupport = hardware.cuda;
        rocmSupport = hardware.rocm;
      };

      _module.args.unstablePkgs = builtins.import inputs.nixpkgs-unstable {
        inherit (config.nixpkgs) system config overlays;
      };
    };

  self.homeModules.nixpkgs.value = { osConfig, ... }: {
    _module.args.unstablePkgs = osConfig._module.args.unstablePkgs;
  };
}
