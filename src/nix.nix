{
  config,
  nixpkgs,
  lib,
  ...
}:

let
  thisOptions = {
    dot.nix.gc = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
  };

  thisConfig = {
    nix.registry.nixpkgs.flake = nixpkgs;

    nix.extraOptions = "experimental-features = nix-command flakes recursive-nix";

    nix.settings.max-jobs = config.dot.hardware.threads / 3;
    nix.settings.cores = 2;

    nix.gc = lib.mkIf config.dot.nix.gc {
      automatic = true;
      options = "--delete-older-than 30d";
    };
    nix.settings.auto-optimise-store = true;

    nix.settings.trusted-users = [
      "root"
      "@wheel"
    ];

    nix.settings.substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      "https://haras.cachix.org"
      "https://hyprland.cachix.org"
      "https://ai.cachix.org"
      "https://cuda-maintainers.cachix.org"
    ];
    nix.settings.trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "haras.cachix.org-1:/HIo1JYqOIH1Nwk1EGXhuPPvDW0WekxIbY5CiXUZbYw="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "ai.cachix.org-1:N9dzRK+alWwoKXQlnn0H6aUx0lU/mspIoz8hMvGvbbc="
      "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
    ];
  };
in
{
  nixosModule = {
    options = thisOptions;
    config = thisConfig;
  };

  homeManagerModule = {
    options = thisOptions;
    config = thisConfig;
  };
}
