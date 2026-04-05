# TODO: assess and maybe switch?

let
  common =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      # nixpkgs.overlays = [
      #   (final: prev: {
      #     inherit (prev.lixPackageSets.stable)
      #       nixpkgs-review
      #       nix-eval-jobs
      #       nix-fast-build
      #       colmena
      #       ;
      #   })
      # ];

      # nix.package = pkgs.lixPackageSets.stable.lix;
    };
in
{
  flake.nixosModules.nix = {
    imports = [ common ];
  };

  flake.homeModules.nix = {
    imports = [ common ];
  };
}
