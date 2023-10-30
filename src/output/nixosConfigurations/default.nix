{ self
, flake-utils
, nixpkgs
, nur
  # TODO: fix infinite recursion?
  # , nixos-wsl
  # , sops-nix
, home-manager
, lulezojne
, ...
} @ inputs:

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
    configName = "${config.hostName}-${config.system}";
    configModules = import "${host}/${config.hostName}";
    metaConfigModule = if builtins.hasAttr "meta" configModules then configModules.meta else { };
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

          networking.hostName = "${username}-${config.hostName}";

          system.stateVersion = "23.11";
        })
        # TODO: fix infinite recursion?
        # NOTE: im guessing because the option declaration from wsl depends on option definition here
        # ({ config, ... }: {
        #   imports =
        #     if config.dot.wsl then [
        #       nixos-wsl.nixosModules.wsl
        #     ] else [ ];
        #   wsl.defaultUser = "${username}";
        # })
        # ({ config, ... }: {
        #   imports =
        #     if config.dot.secrets then [
        #       sops-nix.nixosModules.sops
        #     ] else [ ];
        #   sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
        #   sops.age.keyFile = "/var/lib/sops-nix/key.txt";
        #   sops.age.generateKey = true;
        # })
        metaConfigModule
        systemConfigModule
        ({ pkgs, config, ... }:
          if hasUserConfigModule then {
            imports = [
              home-manager.nixosModules.home-manager
            ];
            users.users."${username}" = {
              isNormalUser = true;
              initialPassword = username;
              extraGroups = [ "wheel" ] ++ config.dot.user.groups;
              shell = pkgs."${config.dot.user.shell.pkg}";
            };
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = specialArgs;
            home-manager.sharedModules = metaModules ++ [
              nur.hmModules.nur
              lulezojne.homeManagerModules.default
              metaConfigModule
            ];
            home-manager.users."${username}" =
              ({ self, pkgs, ... }:
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
                in
                {
                  imports = [
                    userConfigModule
                  ];

                  programs.home-manager.enable = true;
                  nixpkgs.config = import "${self}/src/nixpkgs-config.nix";
                  xdg.configFile."nixpkgs/config.nix".text = "${self}/src/nixpkgs-config.nix";
                  home.username = "${username}";
                  home.homeDirectory = "/home/${username}";
                  home.stateVersion = "23.11";
                  home.packages = [ rebuild ];
                });
          }
          else { }
        )
      ];
    };
  })
{ }
  configs
