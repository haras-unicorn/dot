{ inputs, ... }:

{
  machines.nixosModules.machine =
    { config, ... }:
    {
      imports = [
        inputs.nur.modules.nixos.default
        inputs.nixos-facter-detection-modules.nixosModules.default
        inputs.home-manager.nixosModules.default
        inputs.stylix.nixosModules.stylix
      ];

      users.mutableUsers = false;
      users.groups.${config.dot.user.group} = { };
      users.users.${config.dot.user.user} = {
        isNormalUser = true;
        extraGroups = [ "wheel" ];
        home = "/home/${config.dot.user.user}";
        initialPassword = config.dot.user.user;
        createHome = true;
      };

      home-manager.backupFileExtension = "backup";
      home-manager.users.${config.dot.user.user} = {
        imports = [
          inputs.nur.modules.homeManager.default
          inputs.nix-index-database.homeModules.nix-index
        ];

        home.username = config.dot.user.user;
        home.homeDirectory = "/home/${config.dot.user.user}";

        home.stateVersion = "24.11";
      };

      system.stateVersion = "24.11";
    };
}
