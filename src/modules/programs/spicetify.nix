{ inputs, ... }:

# NOTE: requires gnome-keyring so if you just closed it
# on login it will display a black window

{
  self.nixpkgs.config.allowUnfreePackageNames = [ "spotify" ];

  self.homeModules.spicetify.value =
    {
      lib,
      osConfig,
      pkgs,
      config,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;

      spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
    in
    {
      imports = [
        inputs.spicetify-nix.homeManagerModules.spicetify
      ];

      config = lib.mkIf hardware.gaming {
        programs.spicetify = {
          enable = true;
          enabledExtensions = [
            spicePkgs.extensions.hidePodcasts
            spicePkgs.extensions.aiBandBlocker
          ];

          wayland = hardware.wayland;
        };
      };
    };
}
