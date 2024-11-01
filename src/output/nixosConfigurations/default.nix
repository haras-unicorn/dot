{ self
, flake-utils
, nixpkgs
, nur
, home-manager
, nixos-wsl
, sops-nix
, nix-index-database
, dot
, nixos-facter-modules
, ...
} @ inputs:

# FIXME: https://github.com/NixOS/nixpkgs/issues/315574
# TODO: secure boot (https://nixos.wiki/wiki/Secure_Boot)
# TODO: home encryption and zfs (https://www.reddit.com/r/NixOS/comments/tzksw4/mount_an_encrypted_zfs_datastore_on_login/)
# TODO: hashed password
# TODO: clean this up a bit

let
  userName = "haras";
  vpnHost = "mikoshi";
  vpnDomain = "haras-unicorn.xyz";
  stateVersion = "24.05";

  systems = flake-utils.lib.defaultSystems;
  hostNames = (builtins.attrNames (builtins.readDir "${self}/src/host"));
  configs = nixpkgs.lib.cartesianProduct {
    system = systems;
    hostName = hostNames;
  };

  nixConfigModule = ({ pkgs, ... }: {
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
    nix.settings.allowed-users = [
      "root"
      "@wheel"
    ];
    nix.settings.trusted-users = [
      "root"
      "@wheel"
    ];
  });

  nixpkgsConfigModule = ({ nix-vscode-extensions, ... }: {
    nixpkgs.config = {
      allowUnfree = true;
    };
    nixpkgs.overlays = [
      nix-vscode-extensions.overlays.default
    ];
  });

  mkRebuild = ({ pkgs, config, hostName, system, ... }:
    pkgs.writeShellApplication {
      name = "rebuild";
      runtimeInputs = [ ];
      text = ''
        if [[ ! -d "${config.xdg.dataHome}/dot" ]]; then
          echo "Please clone/link your dotfiles flake into '${config.xdg.dataHome}/dot'"
          exit 1
        fi

        sudo nixos-rebuild switch --flake "$(readlink -f "${config.xdg.dataHome}/dot")#${hostName}-${system}" "$@"
      '';
    });

  mkRebuildTrace = ({ pkgs, config, hostName, system, ... }:
    pkgs.writeShellApplication {
      name = "rebuild-trace";
      runtimeInputs = [ ];
      text = ''
        if [[ ! -d "${config.xdg.dataHome}/dot" ]]; then
          echo "Please clone/link your dotfiles flake into '${config.xdg.dataHome}/dot'"
          exit 1
        fi

        sudo nixos-rebuild switch --flake "$(readlink -f "${config.xdg.dataHome}/dot")#${hostName}-${system}" --show-trace --option eval-cache false "$@"
      '';
    });

  mkRebuildWip = ({ pkgs, config, hostName, userName, system, ... }:
    pkgs.writeShellApplication {
      name = "rebuild-wip";
      runtimeInputs = [ ];
      text = ''
        if [[ ! -d "${config.xdg.dataHome}/dot" ]]; then
          echo "Please clone/link your dotfiles flake into '${config.xdg.dataHome}/dot'"
          exit 1
        fi

        cd "${config.xdg.dataHome}/dot"
        git add .
        git commit -m "WIP"
        git push
        sudo nixos-rebuild switch --flake "$(readlink -f "${config.xdg.dataHome}/dot")#${hostName}-${system}" "$@"
      '';
    });

  groupOptionsModule = ({ lib, ... }: {
    options = {
      dot = {
        groups = lib.mkOption {
          type = with lib.types; listOf str;
          default = [ ];
          example = [ "libvirtd" "docker" "podman" "video" "audio" ];
        };
      };
    };
  });

  mkUserModule = (userName: dotModule: { config, hostName, ... }: {
    users.users."${userName}" = {
      home = "/home/${userName}";
      createHome = true;
      isNormalUser = true;
      initialPassword = userName;
      extraGroups = [ "wheel" ] ++ config.dot.groups;
      useDefaultShell = true;
    };
    home-manager.users."${userName}" = ({ self, pkgs, ... } @inputs: {
      imports = [
        (dot.modules.mkHomeUserModule "${userName}" dotModule)
      ];

      home.stateVersion = stateVersion;
      home.username = "${userName}";
      home.homeDirectory = "/home/${userName}";
      home.packages = [ (mkRebuild inputs) (mkRebuildTrace inputs) (mkRebuildWip inputs) ];

      sops.defaultSopsFile = "${self}/src/host/${hostName}/${userName}.sops.enc.yaml";
      sops.age.keyFile = "/home/${userName}/.sops/secrets.age";
    });
  });
in
builtins.foldl'
  (nixosConfigurations: config:
  let
    hostName = config.hostName;
    system = config.system;
    configName = "${hostName}-${system}";
    dotModule = import "${self}/src/host/${hostName}";
    specialArgs = inputs // {
      inherit system;
      inherit hostName;
      inherit userName;
      inherit vpnHost;
      inherit vpnDomain;
      inherit stateVersion;
    };
  in
  nixosConfigurations // {
    "${configName}" = nixpkgs.lib.nixosSystem {
      inherit system specialArgs;
      modules = [
        nur.nixosModules.nur
        inputs.nixos-facter-modules.nixosModules.facter
        { facter.reportPath = "${self}/src/host/${hostName}/facter.json"; }
        nixos-wsl.nixosModules.wsl
        { wsl.defaultUser = "${userName}"; }
        sops-nix.nixosModules.sops
        ({ self, hostName, ... }: {
          sops.defaultSopsFile = "${self}/src/host/${hostName}/secrets.sops.enc.yaml";
          sops.age.keyFile = "/root/.sops/secrets.age";
        })
        nixConfigModule
        ({ pkgs, ... }: { nix.package = pkgs.nixVersions.stable; })
        nixpkgsConfigModule
        ({ pkgs, ... }: {
          networking.hostName = "${hostName}";
          environment.shells = [ "${pkgs.bashInteractiveFHS}/bin/bash" ];
          users.defaultUserShell = "${pkgs.bashInteractiveFHS}/bin/bash";
          users.mutableUsers = false;
          system.stateVersion = stateVersion;
        })
        (dot.modules.mkSystemModule dotModule)
        home-manager.nixosModules.home-manager
        ({
          home-manager.backupFileExtension = "backup";
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = specialArgs;
          home-manager.sharedModules = [
            nur.hmModules.nur
            nix-index-database.hmModules.nix-index
            nixConfigModule
            nixpkgsConfigModule
            sops-nix.homeManagerModules.sops
            groupOptionsModule
            (dot.modules.mkHomeSharedModule dotModule)
          ];
        })
        groupOptionsModule
        (mkUserModule userName dotModule)
        ({ pkgs, config, ... } @inputs: {
          imports = builtins.map
            (userName: mkUserModule userName dotModule)
            (builtins.filter
              (x: x != userName)
              (dot.modules.definedUsers dotModule inputs));
        })
      ];
    };
  })
  ({ })
  configs
