{ inputs, ... }:

let
  makeNix =
    lib: config:
    let
      hardware = config.dot.hardware;
    in
    {
      registry.nixpkgs.flake = inputs.nixpkgs;

      extraOptions = "experimental-features = nix-command flakes";

      settings.max-jobs = hardware.threads / 3;
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
        "https://haras.cachix.org"
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "https://cuda-maintainers.cachix.org"
        "https://comfyui.cachix.org"
        "https://cache.numtide.com"
        "https://noctalia.cachix.org"
      ];
      settings.trusted-public-keys = [
        "haras.cachix.org-1:/HIo1JYqOIH1Nwk1EGXhuPPvDW0WekxIbY5CiXUZbYw="
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
        "comfyui.cachix.org-1:33mf9VzoIjzVbp0zwj+fT51HG0y31ZTK3nzYZAX0rec="
        "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
        "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      ];
    };
in
{
  machines.nixosModules.nix =
    { lib, config, ... }:
    {
      nix = makeNix lib config;
    };

  machines.homeModules.nix =
    { lib, osConfig, ... }:
    {
      nix = makeNix lib osConfig;
    };
}
