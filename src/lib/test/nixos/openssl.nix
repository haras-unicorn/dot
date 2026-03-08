{ self, ... }:

{
  libAttrs.test.nixosModules.openssl =
    { lib, config, ... }:
    {
      imports = [
        self.nixosModules.critical-openssl
        self.nixosModules.critical-openssl-nixpkgs
      ];

      options.dot.test = {
        openssl = {
          enable = lib.mkEnableOption "openssl test";
        };
      };

      config = lib.mkMerge [
        ({ dot.openssl.enable = lib.mkDefault false; })
        (lib.mkIf config.dot.test.openssl.enable {
          dot.openssl.enable = true;
        })
      ];
    };
}
