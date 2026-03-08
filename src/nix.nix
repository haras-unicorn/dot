{ inputs, ... }:

let
  common =
    { lib, config, ... }:
    {
      options.dot = {
        nix.gc = lib.mkEnableOption "Nix GC";
      };

      config = {
        nix = {
          registry.nixpkgs.flake = inputs.nixpkgs;

          extraOptions = "experimental-features = nix-command flakes recursive-nix";

          settings.max-jobs = config.dot.hardware.threads / 3;
          settings.cores = 2;

          gc = lib.mkIf config.dot.nix.gc {
            automatic = true;
            options = "--delete-older-than 30d";
          };
          settings.auto-optimise-store = true;

          settings.trusted-users = [
            "root"
            "@wheel"
          ];

          settings.substituters = [
            "https://cache.nixos.org"
            "https://nix-community.cachix.org"
            "https://haras.cachix.org"
            "https://hyprland.cachix.org"
            "https://ai.cachix.org"
            "https://cuda-maintainers.cachix.org"
            "https://comfyui.cachix.org"
            "https://cache.numtide.com"
          ];
          settings.trusted-public-keys = [
            "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
            "haras.cachix.org-1:/HIo1JYqOIH1Nwk1EGXhuPPvDW0WekxIbY5CiXUZbYw="
            "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
            "ai.cachix.org-1:N9dzRK+alWwoKXQlnn0H6aUx0lU/mspIoz8hMvGvbbc="
            "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
            "comfyui.cachix.org-1:33mf9VzoIjzVbp0zwj+fT51HG0y31ZTK3nzYZAX0rec="
            "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
          ];
        };
      };
    };
in
{
  flake.nixosModules.nix =
    {
      config,
      lib,
      ...
    }:
    {
      imports = [ common ];

      dot.nix.gc = lib.mkDefault true;
    };

  flake.homeModules.nix =
    {
      config,
      osConfig,
      lib,
      ...
    }:
    {
      imports = [ common ];

      dot.nix.gc = lib.mkDefault osConfig.dot.nix.gc;
    };
}
