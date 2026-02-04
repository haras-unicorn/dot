{
  config,
  lib,
  nixpkgs-unstable,
  nixpkgs-ai,
  pkgs,
  ...
}:

let
  thisConfig = {
    _module.args.unstablePkgs = import nixpkgs-unstable {
      system = pkgs.stdenv.hostPlatform.system;
      config = config.nixpkgs.config;
      overlays = config.nixpkgs.overlays;
    };

    _module.args.aiPkgs = import nixpkgs-ai {
      system = pkgs.stdenv.hostPlatform.system;
      config = config.nixpkgs.config;
      overlays = config.nixpkgs.overlays;
    };

    nixpkgs.config = {
      allowUnfree = true;
      nvidia.acceptLicense = config.dot.hardware.graphics.driver == "nvidia";
      cudaSupport =
        (config.dot.hardware.graphics.driver == "nvidia")
        && (
          (config.dot.hardware.graphics.version == "latest")
          || (config.dot.hardware.graphics.version == "production")
        );
      rocmSupport =
        # NOTE: lots of packages broken right now
        # config.dot.hardware.graphics.driver == "amdgpu"
        false;
    };

    nixpkgs.overlays = lib.mkIf config.dot.hardware.rpi."4".enable [
      (final: prev: {
        # NOTE: https://github.com/NixOS/nixpkgs/issues/154163#issuecomment-1008362877
        makeModulesClosure = x: prev.makeModulesClosure (x // { allowMissing = true; });
      })
    ];
  };
in
{
  eval.allowedArgs = [
    "unstablePkgs"
    "aiPkgs"
  ];

  nixosModule = {
    config = thisConfig;
  };

  homeManagerModule = {
    config = thisConfig;
  };
}
