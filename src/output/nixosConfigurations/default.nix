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

# TODO: home encryption and zfs
# TODO: hashed password
# TODO: make all modules have hardware/system/user parts
# TODO: remove allowUnfree from config?
# TODO: try grub alternatives

let
  meta = self + "/src/meta";
  metaModuleNames = (builtins.attrNames (builtins.readDir meta));
  metaModules = builtins.map (name: "${meta}/${name}") metaModuleNames;

  username = "haras";
  systems = flake-utils.lib.defaultSystems;

  host = self + "/src/host";
  hostNames = (builtins.attrNames (builtins.readDir host));

  configs = nixpkgs.lib.cartesianProductOfSets {
    system = systems;
    hostName = hostNames;
  };

  specialArgs = inputs;
in
builtins.foldl'
  (nixosConfigurations: config:
  let
    hostName = config.hostName;
    system = config.system;
    configName = "${hostName}-${system}";
    configModules = import "${host}/${config.hostName}";
    metaConfigModule = if builtins.hasAttr "meta" configModules then configModules.meta else { };
    hardwareConfigModule = if builtins.hasAttr "hardware" configModules then configModules.hardware else { };
    systemConfigModule = if builtins.hasAttr "system" configModules then configModules.system else { };
    hasUserConfigModule = builtins.hasAttr "user" configModules;
    userConfigModule = if hasUserConfigModule then configModules.user else { };
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
            "https://cache.nixos.org/"
            "https://haras.cachix.org/"
            "https://hyprland.cachix.org"
            "https://ai.cachix.org/"
          ];
          nix.settings.trusted-substituters = [
            "https://cache.nixos.org/"
            "https://haras.cachix.org/"
          ];
          nix.settings.trusted-public-keys = [
            "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
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

          nixpkgs.config = import "${self}/src/nixpkgs-config.nix";

          networking.hostName = "${username}-${hostName}";

          environment.shells = [ "${pkgs.bashInteractiveFHS}/bin/bash" ];
          users.defaultUserShell = "${pkgs.bashInteractiveFHS}/bin/bash";

          system.stateVersion = "23.11";
        })
        nixos-wsl.nixosModules.wsl # NOTE: anabled with wsl.enable
        ({ lib, config, ... }: lib.mkIf config.dot.wsl {
          wsl.enable = true;
          wsl.defaultUser = "${username}";
        })
        sops-nix.nixosModules.sops # NOTE: enabled when at least one secret is added
        ({ lib, config, sops-nix, ... }: lib.mkIf config.dot.secrets {
          sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
          sops.age.keyFile = "/var/lib/sops-nix/key.txt";
          sops.age.generateKey = true;
        })
        metaConfigModule
        hardwareConfigModule
        systemConfigModule
        ({ pkgs, config, ... }:
          if hasUserConfigModule then {
            imports = [
              home-manager.nixosModules.home-manager
            ];
            users.users."${username}" = {
              home = "/home/${username}";
              createHome = true;
              isNormalUser = true;
              initialPassword = username;
              extraGroups = [ "wheel" ] ++ config.dot.groups;
              useDefaultShell = true;
            };
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = specialArgs;
            home-manager.sharedModules = metaModules ++ [
              nur.hmModules.nur
              lulezojne.homeManagerModules.default
              metaConfigModule
              userConfigModule
            ];
            home-manager.users."${username}" = ({ self, pkgs, ... }:
              let
                # TODO: figure out a cleaner way to do this
                rebuild = pkgs.writeShellApplication {
                  name = "rebuild";
                  runtimeInputs = [ ];
                  text = ''
                    if [[ ! -d "/home/${username}/src/dot" ]]; then
                      echo "Please clone/link your dotfiles flake into '/home/${username}/src/dot'"
                      exit 1
                    fi

                    sudo nixos-rebuild switch --flake "/home/${username}/src/dot#${configName}" "$@"
                  '';
                };

                # TODO: figure out a cleaner way to do this
                rebuild-wip = pkgs.writeShellApplication {
                  name = "rebuild-wip";
                  runtimeInputs = [ ];
                  text = ''
                    if [[ ! -d "/home/${username}/src/dot" ]]; then
                      echo "Please clone/link your dotfiles flake into '/home/${username}/src/dot'"
                      exit 1
                    fi

                    cd "/home/${username}/src/dot"
                    git add .
                    git commit -m "WIP"
                    git push
                    sudo nixos-rebuild switch --flake "/home/${username}/src/dot#${configName}" "$@"
                  '';
                };
              in
              {
                programs.home-manager.enable = true;
                nixpkgs.config = import "${self}/src/nixpkgs-config.nix";
                xdg.configFile."nixpkgs/config.nix".text = "${self}/src/nixpkgs-config.nix";
                home.username = "${username}";
                home.homeDirectory = "/home/${username}";
                home.stateVersion = "23.11";
                home.packages = [ rebuild rebuild-wip ];

                services.spotifyd.settings.global.device_name = "${username}-${hostName}";
              });
          }
          else { }
        )
      ];
    };
  })
{ }
  configs
