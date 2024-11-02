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

    lanzaboote.url = "github:nix-community/lanzaboote/v0.4.1";
    lanzaboote.inputs.nixpkgs.follows = "nixpkgs";

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

  outputs =
    { self
    , flake-utils
    , nixpkgs
    , nix-index-database
    , home-manager
    , nur
    , nixos-facter-modules
    , sops-nix
    , ...
    } @ inputs:
    let
      user = "haras";
      version = "24.05";

      importDir = (dir: nixpkgs.lib.attrsets.mapAttrs'
        (name: type: {
          name =
            if type == "regular" then
              (builtins.replaceStrings [ ".nix" ] [ "" ] name) else
              name;
          value = import "${dir}/${name}";
        })
        (builtins.readDir dir));

      lib = importDir "${self}/src/lib";
      modules = builtins.attrValues (importDir "${self}/src/module");
    in
    flake-utils.lib.eachDefaultSystem
      (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            # Nix
            nil
            nixpkgs-fmt

            # Scripts
            nodePackages.bash-language-server
            shfmt
            shellcheck
            yapf
            ruff

            # Misc
            nodePackages.prettier
            nodePackages.yaml-language-server
            nodePackages.vscode-json-languageserver
            marksman
            taplo
            html-tidy

            # Tools
            nushell
            just
            openssl
            openvpn
            openssh
            age
            sops
          ];
        };
      }) // {
      nixosConfigurations =
        let
          hosts = (builtins.attrNames (builtins.readDir "${self}/src/host"));
          configs = nixpkgs.lib.cartesianProduct {
            system = flake-utils.lib.defaultSystems;
            host = hosts;
          };

          mkNixosConfiguration = { system, host }:
            let
              specialArgs = inputs // { inherit version host user; };

              config = import "${self}/src/host/${host}/config.nix";
              hardware = "${self}/src/host/${host}/hardware.json";
              secrets = "${self}/src/host/${host}/secrets.yaml";
            in
            {
              "${host}-${system}" = nixpkgs.lib.nixosSystem {
                inherit system specialArgs;
                modules = [
                  nur.nixosModules.nur
                  nixos-facter-modules.nixosModules.facter
                  sops-nix.nixosModules.sops
                  (lib.dot.mkSystemModule config)
                  home-manager.nixosModules.home-manager
                  {
                    import = builtins.map lib.dot.mkSystemModule modules;

                    fileSystems."/" = {
                      device = "/dev/disk/by-label/NIXROOT";
                      fsType = "ext4";
                    };
                    fileSystems."/boot" = {
                      device = "/dev/disk/by-label/NIXBOOT";
                      fsType = "vfat";
                    };

                    facter.reportPath = hardware;

                    sops.defaultSopsFile = secrets;
                    sops.age.keyFile = "/root/.sops/secrets.age";

                    networking.hostName = host;
                    system.stateVersion = version;

                    users.mutableUsers = false;
                    users.users."${user}" = {
                      home = "/home/${user}";
                      createHome = true;
                      isNormalUser = true;
                      initialPassword = user;
                      extraGroups = [ "wheel" ];
                      useDefaultShell = true;
                    };

                    home-manager.backupFileExtension = "backup";
                    home-manager.useUserPackages = true;
                    home-manager.extraSpecialArgs = specialArgs;
                    home-manager.sharedModules = [
                      nur.hmModules.nur
                      nix-index-database.hmModules.nix-index
                      sops-nix.homeManagerModules.sops
                      (lib.dot.mkHomeSharedModule config)
                    ];
                    home-manager.users."${user}" = ({ self, pkgs, ... }: {
                      imports = builtins.map lib.dot.mkHomeSharedModule modules;

                      home.stateVersion = version;
                      home.username = "${user}";
                      home.homeDirectory = "/home/${user}";

                      sops.defaultSopsFile = "${self}/src/host/${host}/${user}.sops.enc.yaml";
                      sops.age.keyFile = "/home/${user}/.sops/secrets.age";
                    });
                  }
                ];
              };
            };
        in
        nixpkgs.lib.attrsets.mergeAttrsList
          (builtins.map mkNixosConfiguration configs);
    };
}
