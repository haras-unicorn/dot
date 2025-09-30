{ config, ... }:

let
  builders = config.dot.hardware.threads * 2 / 3;
in
{
  branch.nixosModule.nixosModule = {
    nix.settings.max-jobs = builders;
    nix.settings.cores = builders;
  };

  branch.homeManagerModule.homeManagerModule = {
    nix.settings.max-jobs = builders;
    nix.settings.cores = builders;
  };
}
