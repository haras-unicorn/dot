{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";

    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/release-23.11";
    nur.url = "github:nix-community/NUR";

    nixos-hardware.url = "github:NixOS/nixos-hardware";
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

    arkenfox-userjs.url = "github:arkenfox/user.js/refs/tags/v110.0";
    arkenfox-userjs.flake = false;

    firefox-gx.url = "github:Godiesc/firefox-gx/refs/tags/v.9.0";
    firefox-gx.flake = false;

    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
    nix-vscode-extensions.inputs.nixpkgs.follows = "nixpkgs";

    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
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
      (outputs: output: outputs // {
        "${output.name}" = output.mkFrom (inputs // {
          dot = (import "${self}/src/lib");
        });
      })
      { }
      outputModules;
}
