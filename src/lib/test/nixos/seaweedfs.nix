{ self, ... }:

{
  libAttrs.test.nixosModules.seaweedfs =
    { lib, config, ... }:
    {
      imports = [
        self.nixosModules.critical-seaweedfs
        self.nixosModules.critical-seaweedfs-nixpkgs-servers
        self.nixosModules.critical-seaweedfs-nixpkgs-clients
        self.nixosModules.critical-seaweedfs-nixpkgs-master
        self.nixosModules.critical-seaweedfs-nixpkgs-volumes
        self.nixosModules.critical-seaweedfs-nixpkgs-filers
        self.nixosModules.critical-seaweedfs-nixpkgs-mounts
      ];

      options.dot.test = {
        seaweedfs = {
          enable = lib.mkEnableOption "SeaweedFS test";
        };
      };

      config = lib.mkIf config.dot.test.seaweedfs.enable {
        dot.seaweedfs.enable = true;
      };
    };
}
