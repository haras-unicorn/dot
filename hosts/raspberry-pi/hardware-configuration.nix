{ nixos-hardware, modulesPath, ... }:

{
  imports = [
    nixos-hardware.nixosModules.raspberry-pi-4
    "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"
  ];

  boot.loader.generic-extlinux-compatible.enable = true;

  # https://github.com/NixOS/nixpkgs/issues/154163#issuecomment-1008362877  
  nixpkgs.overlays = [
    (final: super: {
      makeModulesClosure = x:
        super.makeModulesClosure (x // { allowMissing = true; });
    })
  ];
}
