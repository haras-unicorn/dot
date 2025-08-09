{ pkgs, config, lib, nixpkgs-unstable, nixpkgs-ai, ... }:

let
  host = config.dot.host;

  system = pkgs.system;

  path = "${config.xdg.dataHome}/dot";

  ensure = ''
    if [ ! -d "${path}/.git" ]; then
      ${pkgs.git}/bin/git clone \
        -c user.name=haras \
        -c user.email=social@haras.anonaddy.me \
        https://github.com/haras-unicorn/dot \
        "${path}"
    fi
  '';

  rebuild = pkgs.writeShellApplication {
    name = "rebuild";
    runtimeInputs = [ ];
    text = ''
      ${ensure}
      sudo nixos-rebuild switch \
        --flake "${path}#${host.name}-${system}" \
        "$@"
    '';
  };

  rebuild-wip = pkgs.writeShellApplication {
    name = "rebuild-wip";
    runtimeInputs = [ ];
    text = ''
      ${ensure}

      cd "${path}" && ${pkgs.git}/bin/git add "${path}"
      cd "${path}" && ${pkgs.git}/bin/git commit -m WIP
      cd "${path}" && ${pkgs.git}/bin/git push

      sudo nixos-rebuild switch \
        --flake "${path}#${host.name}-${system}" \
        "$@"
    '';
  };

  rebuild-trace = pkgs.writeShellApplication {
    name = "rebuild-trace";
    runtimeInputs = [ ];
    text = ''
      ${ensure}
      sudo nixos-rebuild switch \
        --flake "${path}#${host.name}-${system}" \
        --show-trace \
        --option eval-cache false \
        "$@"
    '';
  };

  rebuild-chroot = pkgs.writeShellApplication {
    name = "rebuild-chroot";
    runtimeInputs = [ ];
    text = ''
      ${ensure}
      sudo nixos-rebuild switch \
        --flake "${path}#${host.name}-${system}" \
        --option sandbox false \
        --option filter-syscalls false \
        "$@"
    '';
  };

  thisOptions = {
    unstablePkgs = lib.mkOption {
      type = lib.types.raw;
    };

    aiPkgs = lib.mkOption {
      type = lib.types.raw;
    };

    dot.gc = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
  };

  thisConfig = {
    _module.args.unstablePkgs = import nixpkgs-unstable {
      system = pkgs.system;
      config = config.nixpkgs.config;
      overlays = config.nixpkgs.overlays;
    };

    _module.args.aiPkgs = import nixpkgs-ai {
      system = pkgs.system;
      config = config.nixpkgs.config;
      overlays = config.nixpkgs.overlays;
    };

    nix.extraOptions = "experimental-features = nix-command flakes";
    nix.gc = lib.mkIf config.dot.gc {
      automatic = true;
      options = "--delete-older-than 30d";
    };
    nix.settings.auto-optimise-store = true;
    nix.settings.trusted-users = [
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

    nixpkgs.config = {
      allowUnfree = true;
      nvidia.acceptLicense = config.dot.hardware.graphics.driver == "nvidia";
      cudaSupport = (config.dot.hardware.graphics.driver == "nvidia")
        && ((config.dot.hardware.graphics.version == "latest")
        || (config.dot.hardware.graphics.version == "production"));
      rocmSupport =
        # NOTE: lots of packages broken right now
        # config.dot.hardware.graphics.driver == "amdgpu"
        false
      ;
    };

    nixpkgs.overlays = lib.mkIf config.dot.hardware.rpi."4".enable [
      (final: prev: {
        # NOTE: https://github.com/NixOS/nixpkgs/issues/154163#issuecomment-1008362877  
        makeModulesClosure = x: prev.makeModulesClosure
          (x // { allowMissing = true; });
      })
    ];
  };
in
{
  branch.nixosModule.nixosModule = {
    options = thisOptions;

    config = lib.mkMerge [
      thisConfig
      {
        nix.package = pkgs.nixVersions.stable;
      }
    ];
  };

  branch.homeManagerModule.homeManagerModule = {
    options = thisOptions;

    config = lib.mkMerge [
      thisConfig
      {
        home.packages = [ rebuild rebuild-wip rebuild-trace rebuild-chroot ];
        home.activation = {
          ensurePulledAction = lib.hm.dag.entryAfter [ "writeBoundary" ] ensure;
        };
      }
    ];
  };
}
