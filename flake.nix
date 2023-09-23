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
                  shell = "nushell";
                  # ip address
                  # hyprctl monitors
                  hardware = { };
                } // (if builtins.pathExists "${hosts}/${host}/meta.nix"
                then builtins.import "${hosts}/${host}/meta.nix"
                else { });

              specialArgs = {
                self = self;
                nixos-wsl = nixos-wsl;
                nixos-hardware = nixos-hardware;
                sweet-theme = sweet-theme;
                hardware = meta.hardware;
              };
            in
            nixosConfigurations // {
              "${host}" =
                nixpkgs.lib.nixosSystem
                  {
                    system = meta.system;
                    specialArgs = specialArgs;
                    modules = [
                      ({ pkgs, ... }: {
                        nix.package = pkgs.nixFlakes;
                        nix.extraOptions = "experimental-features = nix-command flakes";
                        nixpkgs.config = import "${self}/src/nixpkgs-config.nix";
                        networking.hostName = meta.hostname;
                        system.stateVersion = "23.11";
                      })
                      "${hosts}/${host}/hardware-configuration.nix"
                      "${hosts}/${host}/configuration.nix"
                    ]
                    ++ (if (builtins.pathExists "${hosts}/${host}/home.nix") then [
                      ({ pkgs, ... }: {
                        users.users."${username}" = {
                          isNormalUser = true;
                          initialPassword = username;
                          extraGroups = [ "wheel" ] ++ meta.groups;
                          shell = pkgs."${meta.shell}";
                        };
                      })
                      home-manager.nixosModules.home-manager
                      {
                        # NOTE: it seems docs recommend this but i need it disabled cuz nodejs
                        # home-manager.useGlobalPkgs = true;
                        home-manager.useUserPackages = true;
                        home-manager.extraSpecialArgs = specialArgs;
                        home-manager.sharedModules = [
                          lulezojne.nixosModules.default
                        ];
                        home-manager.users."${username}" =
                          ({ ... }:
                            {
                              programs.home-manager.enable = true;
                              nixpkgs.config = import "${self}/src/nixpkgs-config.nix";
                              xdg.configFile."nixpkgs/config.nix".text = "${self}/src/nixpkgs-config.nix";
                              home.username = "${username}";
                              home.homeDirectory = "/home/${username}";
                              home.stateVersion = "23.11";
                              imports = [
                                "${hosts}/${host}/home.nix"
                              ];
                            });
                      }
                    ] else [ ])
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
                    ] else [ ]);
                  };
            }
          )
          { }
          (builtins.attrNames
            (builtins.readDir hosts));
    };
}
