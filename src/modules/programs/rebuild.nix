{
  self.homeModules.rebuild.value =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.harasPackages.rebuild
        pkgs.harasPackages.rebuild-trace
        pkgs.harasPackages.rebuild-chroot
      ];
    };
}
