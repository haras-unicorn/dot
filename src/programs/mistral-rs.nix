{ unstablePkgs, ... }:

{
  homeManagerModule = {
    home.packages = [
      unstablePkgs.mistral-rs
    ];
  };
}
