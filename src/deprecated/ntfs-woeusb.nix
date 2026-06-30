{
  self.lib.deprecated.nixosModules.ntfs-woeusb =
    {
      pkgs,
      lib,
      ...
    }:
    lib.mkIf (pkgs.stdenv.hostPlatform.system == "x86_64-linux") {
      environment.systemPackages = with pkgs; [
        ntfs3g
        woeusb
      ];
    };
}
