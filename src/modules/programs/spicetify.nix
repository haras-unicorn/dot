{ inputs, ... }:

# NOTE: requires gnome-keyring so if you just closed it
# on login it will display a black window

{
  machines.nixosModules.spicetify =
    { lib, config, ... }:
    let
      hardware = config.dot.hardware;
    in
    lib.mkIf hardware.gaming {
      dot.nixpkgs.allowUnfreePredicates = [
        (
          package:
          let
            name = lib.getName package;
          in
          name == "spotify"
        )
      ];
    };

  machines.homeModules.spicetify =
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
          enabledExtensions = with spicePkgs.extensions; [
            hidePodcasts
            aiBandBlocker
          ];

          wayland = hardware.wayland;
        };
      };
    };
}
