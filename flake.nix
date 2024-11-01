{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";

    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager/release-24.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nur.url = "github:nix-community/NUR";

    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
    nix-vscode-extensions.inputs.nixpkgs.follows = "nixpkgs";

    nixos-facter-modules.url = "github:numtide/nixos-facter-modules";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    arkenfox-userjs.url = "github:arkenfox/user.js/refs/tags/v110.0";
    arkenfox-userjs.flake = false;

    firefox-gx.url = "github:Godiesc/firefox-gx/refs/tags/v.9.0";
    firefox-gx.flake = false;

    tint-gear.url = "github:haras-unicorn/tint-gear";
    tint-gear.inputs.nixpkgs.follows = "nixpkgs";

    nix-colors.url = "github:Misterio77/nix-colors";

    nix-comfyui.url = "github:haras-unicorn/nix-comfyui/dev";
    nix-comfyui.inputs.nixpkgs.follows = "nixpkgs";
    nix-comfyui.inputs.flake-utils.follows = "flake-utils";
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
