{ self, ... }:

{
  libAttrs.test.nixosModules.cockroachdb =
    { lib, config, ... }:
    {
      imports = [
        self.nixosModules.critical-cockroachdb
        self.nixosModules.critical-cockroachdb-nixpkgs
        self.nixosModules.critical-cockroachdb-apps
        self.nixosModules.critical-cockroachdb-root
        self.nixosModules.critical-cockroachdb-user
        self.nixosModules.critical-cockroachdb-backup
        self.nixosModules.critical-cockroachdb-builtin-backup
        self.nixosModules.critical-cockroachdb-ca
      ];

      options.dot.test = {
        cockroachdb = {
          enable = lib.mkEnableOption "CockroachDB test";
        };
      };

      config = lib.mkIf config.dot.test.cockroachdb.enable {
        dot.cockroachdb.enable = true;
        dot.cockroachdb.enableRootConnection = true;

        nixpkgs.config = {
          allowUnfree = true;
        };
      };
    };
}
