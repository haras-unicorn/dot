{ lib, self, ... }:

{
  libAttrs.test = {
    mkTest =
      originalPkgs: module:
      let
        nixpkgs = self.lib.nixpkgs.patch originalPkgs;

        pkgs = import nixpkgs {
          system = originalPkgs.stdenv.hostPlatform.system;
        };

        mkTest =
          { withSshBackdoor }:
          pkgs.testers.runNixOSTest {
            imports = [ module ] ++ (builtins.attrValues self.lib.test.modules);
            sshBackdoor.enable = withSshBackdoor;
            # NOTE: needed to set nixpkgs config
            node.pkgsReadOnly = false;
            defaults = {
              imports =
                (builtins.attrValues (
                  lib.filterAttrs (name: _: lib.hasPrefix "capabilities" name) self.nixosModules
                ))
                ++ (builtins.attrValues self.lib.test.nixosModules);
            };
          };

        original = mkTest { withSshBackdoor = false; };

        withSshBackdoor = mkTest { withSshBackdoor = true; };
      in
      original // { inherit withSshBackdoor; };
  };
}
