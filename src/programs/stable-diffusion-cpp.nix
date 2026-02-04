{ unstablePkgs, ... }:

{
  homeManagerModule = {
    home.packages = [
      unstablePkgs.stable-diffusion-cpp
    ];
  };
}
