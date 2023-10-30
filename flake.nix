{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";

    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/release-23.05";
    nur.url = "github:nix-community/NUR";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nixos-wsl.url = "github:nix-community/NixOS-WSL";
    nixos-wsl.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.inputs.nixpkgs-stable.follows = "nixpkgs-stable";

    lulezojne.url = "github:haras-unicorn/lulezojne";
    lulezojne.inputs.nixpkgs.follows = "nixpkgs";

    nixified-ai.url = "github:nixified-ai/flake";
    nixified-ai.inputs.nixpkgs.follows = "nixpkgs";

    sweet-theme.url = "github:EliverLara/Sweet/nova";
    sweet-theme.flake = false;

    userjs.url = "github:arkenfox/user.js";
    userjs.flake = false;
  };

  outputs = { self, ... } @ inputs:
    let
      outputs = ./src/output;
      outputNames = (builtins.attrNames (builtins.readDir outputs));
      outputModules = builtins.map
        (name: {
          inherit name;
          mkFrom = import "${outputs}/${name}";
        })
        outputNames;
    in
    builtins.foldl' (outputs: output: outputs // { "${output.name}" = output.mkFrom inputs; }) { } outputModules;
}
