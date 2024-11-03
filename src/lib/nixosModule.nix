{ self, nur, nix-index-database, ... }@inputs:

let
  user = self.lib.nixosConfiguration.user;
  version = self.lib.nixosConfiguration.version;
  modules = self.lib.nixosConfiguration.modules;
in
{
  mkNixosModule = host: system:
    let
      specialArgs = inputs // { inherit version host user; };
      config = import "${self}/src/host/${host}/config.nix";
      hardware = "${self}/src/host/${host}/hardware.json";
      secrets = "${self}/src/host/${host}/secrets.yaml";
    in
    {
      import =
        (builtins.map self.lib.module.mkSystemModule modules) ++
        [ (self.lib.module.mkSystemModule config) ];

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
        ({ lib, ... }: {
          options.facter = {
            report = lib.mkOption {
              type = lib.types.raw;
              default = builtins.fromJSON
                (builtins.readFile config.facter.reportPath);
            };

            reportPath = lib.mkOption {
              type = lib.types.path;
              default = hardware;
            };
          };
        })
      ];
      home-manager.users."${user}" = self.hmModules."${host}-${system}";
    };
}
