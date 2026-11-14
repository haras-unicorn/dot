{
  self,
  selfLib,
  inputs,
  ...
}:

{
  self.overlays.overlays.installer.value =
    final: _prev:
    let
      stolonPackages = (final.extend inputs.stolon.overlays.installer).stolonPackages;

      # NOTE: the images have no facter report to find the Wi-Fi stick in,
      # so they always carry its driver
      rtl88x2bu = {
        imports = [ selfLib.rtl88x2bu.module ];

        dot.rtl88x2bu = {
          enable = true;
          countryCode = selfLib.location.countryCode;
        };
      };

      installer = stolonPackages.makeInstaller {
        nixosConfigurations = self.nixosConfigurations;
        repository = self;
        remoteFlakeRef = "github:haras-unicorn/dot";
        imageModules = [
          rtl88x2bu
          # NOTE: the default is slow as heck
          { isoImage.squashfsCompression = "zstd -Xcompression-level 6"; }
        ];
      };

      offlineImages = final.lib.mapAttrs' (
        name: image: final.lib.nameValuePair "${name}-image" image
      ) installer.offlineImages;
    in
    {
      # NOTE: nested because of a current bug in haraspkgs
      # (https://github.com/haras-unicorn/haraspkgs/issues/40)
      # however it will work even after the bug gets fixed
      installer = {
        installer = installer.installer;
        installer-image = installer.image;
      }
      // offlineImages;
    };
}
