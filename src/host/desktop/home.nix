{ self, ... }:

{
  imports = [
    "${self}/src/distro/console/console.nix"
    "${self}/src/distro/app/app.nix"
  ];
}
