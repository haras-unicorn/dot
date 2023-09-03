{ ... }:

{
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  wsl.startMenuLaunchers = true;
  wsl.interop.register = true;
}
