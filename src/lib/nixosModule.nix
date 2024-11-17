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
      specialArgs = inputs // { inherit version host system user; };
      config = import "${self}/src/host/${host}/config.nix";
      shared = "${self}/src/host/shared.nix";
      hardware = "${self}/src/host/${host}/hardware.json";
      secrets = "${self}/src/host/${host}/secrets.yaml";
      scripts = "${self}/src/host/${host}/scripts.json";
    in
    {
      imports =
        (builtins.map self.lib.module.mkSystemModule modules)
        ++ [ (self.lib.module.mkSystemModule config) ]
        ++ (if builtins.pathExists shared
        then [ (self.lib.module.mkSystemModule (import shared)) ]
        else [ ])
        ++ (if builtins.pathExists scripts
        then [ (self.lib.scripts.mkSystemModule scripts) ]
        else [ ]);

      facter.reportPath = hardware;

      sops.defaultSopsFile = secrets;
      sops.age.keyFile = "/root/host.scrt.key";

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
        nixos-facter-modules.hmModules.facter
      ];
      home-manager.users."${user}" = self.hmModules."${host}-${system}";
    };
}
