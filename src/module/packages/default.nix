{ pkgs, config, hostName, system, ... }:

let
  rebuild = pkgs.writeShellApplication {
    name = "rebuild";
    runtimeInputs = [ ];
    text = ''
      sudo nixos-rebuild switch \
        --flake "$(readlink -f "${config.xdg.dataHome}/dot")#${hostName}-${system}" \
        "$@"
    '';
  };

  rebuild-trace = pkgs.writeShellApplication {
    name = "rebuild-trace";
    runtimeInputs = [ ];
    text = ''
      sudo nixos-rebuild switch \
        --flake "$(readlink -f "${config.xdg.dataHome}/dot")#${hostName}-${system}" \
        --show-trace \
        --option eval-cache false \
        "$@"
    '';
  };

  graphicsCardDriver = config.facter.report.hardware.graphics_card.driver;
in
{

  shared = {
    nix.extraOptions = "experimental-features = nix-command flakes";
    nix.gc.automatic = true;
    nix.gc.options = "--delete-older-than 30d";
    nix.settings.auto-optimise-store = true;
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

    nixpkgs.config = {
      allowUnfree = true;
      cudaSupport = graphicsCardDriver == "nvidia";
      rocmSupport = graphicsCardDriver == "amdgpu";
    };
  };

  home = {
    home.packages = [ rebuild rebuild-trace ];
  };

  system = {
    nix.package = pkgs.nixVersions.stable;
  };
}