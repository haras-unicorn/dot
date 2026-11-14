{ inputs, ... }:

{
  self.nixosModules.machine.value =
    { config, ... }:
    let
      home = "/home/${config.dot.user.user}";
    in
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
        inherit home;
        initialPassword = config.dot.user.user;
        createHome = true;
      };

      # NOTE: not read from users.users, because users.users depends on the
      # file systems, which stolon makes from what it keeps
      stolon.keep.directories = [ home ];

      home-manager.backupFileExtension = "backup";
      home-manager.overwriteBackup = true;
      home-manager.useGlobalPkgs = true;
      home-manager.users.${config.dot.user.user} = {
        imports = [
          inputs.nix-index-database.homeModules.nix-index
        ];

        home.username = config.dot.user.user;
        home.homeDirectory = home;

        home.stateVersion = "24.11";
      };

      system.stateVersion = "24.11";
    };
}
