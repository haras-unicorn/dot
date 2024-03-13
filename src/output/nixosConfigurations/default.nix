{ self
, flake-utils
, nixpkgs
, nur
, home-manager
, lulezojne
, nixos-wsl
, sops-nix
, ...
} @ inputs:

# TODO: secure boot (https://nixos.wiki/wiki/Secure_Boot)
# TODO: home encryption and zfs (https://www.reddit.com/r/NixOS/comments/tzksw4/mount_an_encrypted_zfs_datastore_on_login/)
# TODO: hashed password
# TODO: make all modules have hardware/system/user parts

let
  meta = self + "/src/meta";
  metaModuleNames = (builtins.attrNames (builtins.readDir meta));
  metaModules = builtins.map (name: "${meta}/${name}") metaModuleNames;

  userName = "haras";
  vpnHost = "mikoshi";
  vpnDomain = "haras-unicorn.xyz";

  systems = flake-utils.lib.defaultSystems;

  host = self + "/src/host";
  hostNames = (builtins.attrNames (builtins.readDir host));

  configs = nixpkgs.lib.cartesianProductOfSets {
    system = systems;
    hostName = hostNames;
  };
in
builtins.foldl'
  (nixosConfigurations: config:
  let
    hostName = config.hostName;
    system = config.system;
    configName = "${hostName}-${system}";
    configModules = import "${host}/${config.hostName}";
    metaConfigModule = if builtins.hasAttr "meta" configModules then configModules.meta else { };
    nixpkgsConfigModule = if builtins.hasAttr "nixpkgs" configModules then configModules.nixpkgs else { };
    hardwareConfigModule = if builtins.hasAttr "hardware" configModules then configModules.hardware else { };
    systemConfigModule = if builtins.hasAttr "system" configModules then configModules.system else { };
    hasUserConfigModule = builtins.hasAttr "user" configModules;
    userConfigModule = if hasUserConfigModule then configModules.user else { };
    specialArgs = inputs // {
      inherit system;
      inherit hostName;
      inherit userName;
      inherit vpnHost;
      inherit vpnDomain;
    };
  in
  nixosConfigurations // {
    "${configName}" = nixpkgs.lib.nixosSystem {
      system = config.system;
      specialArgs = specialArgs;
      modules = metaModules ++ [
        nur.nixosModules.nur
        ({ self, pkgs, ... }: {
          nix.package = pkgs.nixFlakes;
          nix.extraOptions = "experimental-features = nix-command flakes";

          nix.gc.automatic = true;
          nix.gc.dates = "weekly";
          nix.gc.options = "--delete-older-than 30d";
          nix.settings.auto-optimise-store = true;

          nix.settings.substituters = [
            "https://cache.nixos.org"
            "https://nix-community.cachix.org"
            "https://haras.cachix.org"
            "https://hyprland.cachix.org"
            "https://ai.cachix.org"
          ];
          nix.settings.trusted-substituters = [
            "https://cache.nixos.org"
            "https://nix-community.cachix.org"
            "https://haras.cachix.org"
            "https://hyprland.cachix.org"
            "https://ai.cachix.org"
          ];
          nix.settings.trusted-public-keys = [
            "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
            "haras.cachix.org-1:/HIo1JYqOIH1Nwk1EGXhuPPvDW0WekxIbY5CiXUZbYw="
            "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
            "ai.cachix.org-1:N9dzRK+alWwoKXQlnn0H6aUx0lU/mspIoz8hMvGvbbc="
          ];

          nix.settings.allowed-users = [
            "root"
            "@wheel"
          ];
          nix.settings.trusted-users = [
            "root"
          ];

          networking.hostName = "${hostName}";

          environment.shells = [ "${pkgs.bashInteractiveFHS}/bin/bash" ];
          users.defaultUserShell = "${pkgs.bashInteractiveFHS}/bin/bash";
          users.mutableUsers = false;

          system.stateVersion = "24.05";
        })
        nixos-wsl.nixosModules.wsl # NOTE: anabled with wsl.enable
        ({ lib, config, ... }: lib.mkIf config.dot.wsl {
          wsl.enable = true;
          wsl.defaultUser = "${userName}";
        })
        sops-nix.nixosModules.sops # NOTE: enabled when at least one secret is added
        ({ lib, config, sops-nix, ... }: {
          sops.defaultSopsFile = "${self}/src/host/${hostName}/secrets.sops.enc.yaml";
          sops.age.keyFile = "/root/.sops/secrets.age";
        })
        metaConfigModule
        hardwareConfigModule
        systemConfigModule
        { nixpkgs.config = nixpkgsConfigModule; }
        ({ pkgs, config, ... }:
          if hasUserConfigModule then {
            imports = [
              home-manager.nixosModules.home-manager
            ];
            users.users."${userName}" = {
              home = "/home/${userName}";
              createHome = true;
              isNormalUser = true;
              initialPassword = userName;
              extraGroups = [ "wheel" ] ++ config.dot.groups;
              useDefaultShell = true;
            };
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = specialArgs;
            home-manager.sharedModules = metaModules ++ [
              nur.hmModules.nur
              lulezojne.homeManagerModules.default
              sops-nix.homeManagerModules.sops
              metaConfigModule
              { nixpkgs.config = nixpkgsConfigModule; }
              userConfigModule
            ];
            home-manager.users."${userName}" =
              ({ self, pkgs, ... }:
                let
                  # TODO: figure out a cleaner way to do this
                  rebuild = pkgs.writeShellApplication {
                    name = "rebuild";
                    runtimeInputs = [ ];
                    text = ''
                      if [[ ! -d "/home/${userName}/src/dot" ]]; then
                        echo "Please clone/link your dotfiles flake into '/home/${userName}/src/dot'"
                        exit 1
                      fi

                      sudo nixos-rebuild switch --flake "/home/${userName}/src/dot#${configName}" "$@"
                    '';
                  };

                  # TODO: figure out a cleaner way to do this
                  rebuild-wip = pkgs.writeShellApplication {
                    name = "rebuild-wip";
                    runtimeInputs = [ ];
                    text = ''
                      if [[ ! -d "/home/${userName}/src/dot" ]]; then
                        echo "Please clone/link your dotfiles flake into '/home/${userName}/src/dot'"
                        exit 1
                      fi

                      cd "/home/${userName}/src/dot"
                      git add .
                      git commit -m "WIP"
                      git push
                      sudo nixos-rebuild switch --flake "/home/${userName}/src/dot#${configName}" "$@"
                    '';
                  };
                in
                {
                  programs.home-manager.enable = true;
                  xdg.configFile."nixpkgs/config.nix".source = nixpkgsConfigModule;
                  home.username = "${userName}";
                  home.homeDirectory = "/home/${userName}";
                  home.stateVersion = "24.05";
                  home.packages = [ rebuild rebuild-wip ];
                  sops.defaultSopsFile = "${self}/src/host/${hostName}/${userName}.sops.enc.yaml";
                  sops.age.keyFile = "/home/${userName}/.sops/secrets.age";
                });
          }
          else
            { }
        )
      ];
    };
  })
  ({ })
  configs
