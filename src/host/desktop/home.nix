{ self, ... }:

{
  imports = [
    "${self}/src/distro/console/console.nix"

    # "${self}/src/distro/de-legacy/de-legacy.nix"
    "${self}/src/distro/de/de.nix"

    "${self}/src/distro/app/app.nix"
  ];
}
