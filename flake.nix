{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";

    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/release-23.05";
    nur.url = "github:nix-community/NUR";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nixos-wsl.url = "github:nix-community/NixOS-WSL";
    nixos-wsl.inputs.nixpkgs.follows = "nixpkgs";

    # TODO: make this follow our nixpkgs
    nix-alien.url = "github:thiagokokada/nix-alien";
    nix-alien.inputs.flake-utils.follows = "flake-utils";

    nix-autobahn.url = "github:Lassulus/nix-autobahn";
    nix-autobahn.inputs.flake-utils.follows = "flake-utils";
    nix-autobahn.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.inputs.nixpkgs-stable.follows = "nixpkgs-stable";

    lulezojne.url = "github:haras-unicorn/lulezojne";
    lulezojne.inputs.nixpkgs.follows = "nixpkgs";

    nixified-ai.url = "github:nixified-ai/flake";
    nixified-ai.inputs.nixpkgs.follows = "nixpkgs";

    gpt4all.url = "github:polygon/gpt4all-nix";
    gpt4all.inputs.nixpkgs.follows = "nixpkgs";

    sweet-theme.url = "github:EliverLara/Sweet/nova";
    sweet-theme.flake = false;

    arkenfox-userjs.url = "github:arkenfox/user.js";
    arkenfox-userjs.flake = false;

    firefox-gx.url = "github:Godiesc/firefox-gx/refs/tags/v.8.8";
    firefox-gx.flake = false;
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
    builtins.foldl'
      (outputs: output: outputs // { "${output.name}" = output.mkFrom inputs; })
      { }
      outputModules;
}
