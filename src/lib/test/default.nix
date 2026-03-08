{ lib, self, ... }:

{
  libAttrs.test = {
    mkTest =
      pkgs: module:
      let
        mkTest =
          { withSshBackdoor }:
          pkgs.testers.runNixOSTest {
            imports = [ module ] ++ (builtins.attrValues self.lib.test.modules);
            sshBackdoor.enable = withSshBackdoor;
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
