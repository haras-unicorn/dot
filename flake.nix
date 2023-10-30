{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    nixpkgs-stable.url = "github:NixOS/nixpkgs/release-23.05";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nixos-wsl.url = "github:nix-community/NixOS-WSL";
    nixos-wsl.inputs.nixpkgs.follows = "nixpkgs";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.inputs.nixpkgs-stable.follows = "nixpkgs-stable";

    sweet-theme.url = "github:EliverLara/Sweet/nova";
    sweet-theme.flake = false;

    lulezojne.url = "github:haras-unicorn/lulezojne";
    lulezojne.inputs.nixpkgs.follows = "nixpkgs";

    nixified-ai.url = "github:nixified-ai/flake";
    nixified-ai.inputs.nixpkgs.follows = "nixpkgs";

    nur.url = "github:nix-community/NUR";

    userjs.url = "github:arkenfox/user.js";
    userjs.flake = false;
  };

  outputs =
    { self
    , nixpkgs
    , home-manager
    , sops-nix
    , nixos-wsl
    , nixos-hardware
    , sweet-theme
    , lulezojne
    , nixified-ai
    , nur
    , userjs
    , ...
    }:
    let
      hosts = self + "/src/host";
      username = "haras";
    in
    {
      nixosConfigurations =
        builtins.foldl'
          (nixosConfigurations: host:
            let
              meta =
                {
                  system = "x86_64-linux";
                  wsl = false;
                  hostname = "${host}-${username}";
                  username = username;
                  groups = [ ];
                  hardware = { };
                  pinentry = { };
                } // (if builtins.pathExists "${hosts}/${host}/meta.nix"
                then builtins.import "${hosts}/${host}/meta.nix"
                else { });

              specialArgs = {
                self = self;
                nixos-wsl = nixos-wsl;
                nixos-hardware = nixos-hardware;
                sweet-theme = sweet-theme;
                hardware = meta.hardware;
                gnupg = meta.gnupg;
                nixified-ai = nixified-ai;
                userjs = userjs;
              };
            in
            nixosConfigurations // {
              "${host}" =
                nixpkgs.lib.nixosSystem
                  {
                    system = meta.system;
                    specialArgs = specialArgs;
                    modules = [
                      nur.nixosModules.nur
                      ({ pkgs, ... }: {
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

                        networking.hostName = meta.hostname;

                        system.stateVersion = "23.11";
                      })
                      "${hosts}/${host}/hardware-configuration.nix"
                      "${hosts}/${host}/configuration.nix"
                    ]
                    ++ (if (builtins.pathExists "${hosts}/${host}/secrets.nix") then [
                      sops-nix.nixosModules.sops
                      {
                        sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
                        sops.age.keyFile = "/var/lib/sops-nix/key.txt";
                        sops.age.generateKey = true;
                      }
                      "${hosts}/${host}/secrets.nix"
                    ] else [ ])
                    ++ (if meta.wsl then [
                      nixos-wsl.nixosModules.wsl
                      {
                        wsl.enable = true;
                        wsl.defaultUser = "${meta.username}";
                      }
                    ] else [ ])
                    ++ (if (builtins.pathExists "${hosts}/${host}/home.nix") then [
                      ({ pkgs, ... }: {
                        users.users."${username}" = {
                          isNormalUser = true;
                          initialPassword = username;
                          extraGroups = [ "wheel" ] ++ meta.groups;
                          shell = pkgs.bash;
                        };
                      })
                      home-manager.nixosModules.home-manager
                      {
                        # TODO: remove when migrate the dev stuff to repos
                        # home-manager.useGlobalPkgs = true;
                        home-manager.useUserPackages = true;
                        home-manager.extraSpecialArgs = specialArgs;
                        home-manager.sharedModules = [
                          lulezojne.homeManagerModules.default
                        ];
                        home-manager.users."${username}" =
                          ({ pkgs, ... }:
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

                                  sudo nixos-rebuild switch --flake "/home/${username}/src/dot#${host}" "$@"
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
                              home.packages = [ rebuild ];
                              imports = [
                                nur.hmModules.nur
                                "${hosts}/${host}/home.nix"
                              ];
                            });
                      }
                    ] else [ ]);
                  };
            }
          )
          { }
          (builtins.attrNames
            (builtins.readDir hosts));
    };
}
