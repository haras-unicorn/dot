{ inputs, ... }:

let
  makeNix =
    lib: config:
    let
      hardware = config.dot.hardware;
    in
    {
      registry.nixpkgs.flake = inputs.nixpkgs;

      settings.experimental-features = [
        "nix-command"
        "flakes"
        # NOTE: needed for uid-range
        "auto-allocate-uids"
        # NOTE: needed for uid-range
        "cgroups"
      ];
      settings.system-features = [
        # NOTE: defaults
        "benchmark"
        "big-parallel"
        "kvm"
        "nixos-test"
        # NOTE: needed for nixos container tests
        "uid-range"
      ];
      # NOTE: needed for uid-range
      settings.auto-allocate-uids = true;

      settings.max-jobs = hardware.threads / 3;
      settings.cores = 2;

      gc = lib.mkIf config.dot.nix.gc {
        automatic = true;
        options = "--delete-older-than 30d";
      };
      settings.auto-optimise-store = true;

      settings.allowed-users = [
        "root"
        "@wheel"
      ];
      settings.trusted-users = [
        "root"
        "@wheel"
      ];

      settings.substituters = [
        "https://haras.cachix.org"
        "https://haras-releases.cachix.org"
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "https://cache.nixos-cuda.org"
        "https://comfyui.cachix.org"
        "https://cache.numtide.com"
        "https://noctalia.cachix.org"
      ];
      settings.trusted-public-keys = [
        "haras.cachix.org-1:/HIo1JYqOIH1Nwk1EGXhuPPvDW0WekxIbY5CiXUZbYw="
        "haras-releases.cachix.org-1:DK1D4cU3v6GUkdjynBsjk0cCMtLaueSUCD7wJBPxyMM="
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
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
