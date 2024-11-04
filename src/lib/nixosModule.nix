{ self
, nur
, nix-index-database
, nixos-facter-modules
, ...
}@inputs:

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
      imports =
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
        nur.hmModules.default
        nix-index-database.hmModules.default
        nixos-facter-modules.hmModules.default
      ];
      home-manager.users."${user}" = self.hmModules."${host}-${system}";
    };
}
