{
  description = "My NixOS configurations.";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    import-tree.url = "github:vic/import-tree";

    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    nixos-facter-detection-modules.url = "github:haras-unicorn/nixos-facter-detection-modules/refs/tags/v1.0.0";
    nixos-facter-detection-modules.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # NOTE: https://github.com/nix-community/stylix/blob/e084d011e7ee9302aceaaf6c1fc28a9ace09e16a/doc/src/installation.md#nixos
    stylix.url = "github:danth/stylix/release-26.05";

    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    nur.url = "github:nix-community/NUR";
    nur.inputs.nixpkgs.follows = "nixpkgs";

    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
    nix-vscode-extensions.inputs.nixpkgs.follows = "nixpkgs";

    # NOTE: https://github.com/utensils/comfyui-nix/tree/308a863c136ffc35fce293a81eac5d229b31d56d#binary-cache
    # comfyui-nix.url = "github:utensils/comfyui-nix/refs/tags/v0.25.0";

    musnix.url = "github:musnix/musnix";
    musnix.inputs.nixpkgs.follows = "nixpkgs";

    certilia-overlay.url = "github:marijanp/certilia-overlay";
    certilia-overlay.inputs.nixpkgs.follows = "nixpkgs";

    # NOTE: https://github.com/numtide/llm-agents.nix/tree/8ed00a37b0800e810b8dd16efa2c6d78bdb3a091#binary-cache
    llm-agents.url = "github:numtide/llm-agents.nix";
  };

  outputs =
    { flake-parts, import-tree, ... }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } (import-tree ./src);

  nixConfig = {
    extra-substituters = [
      "https://haras.cachix.org"
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      "https://cuda-maintainers.cachix.org"
      "https://comfyui.cachix.org"
      "https://cache.numtide.com"
    ];
    extra-trusted-public-keys = [
      # cspell:disable
      "haras.cachix.org-1:/HIo1JYqOIH1Nwk1EGXhuPPvDW0WekxIbY5CiXUZbYw="
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
      "comfyui.cachix.org-1:33mf9VzoIjzVbp0zwj+fT51HG0y31ZTK3nzYZAX0rec="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      # cspell:enable
    ];
  };
}
