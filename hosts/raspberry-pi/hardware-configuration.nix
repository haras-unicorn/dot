{ nixos-hardware, ... }:

{
  imports = [
    nixos-hardware.nixosModules.raspberry-pi-4
  ];

  # https://github.com/NixOS/nixpkgs/issues/154163#issuecomment-1008362877  
  nixpkgs.overlays = [
    (final: super: {
      makeModulesClosure = x:
        super.makeModulesClosure (x // { allowMissing = true; });
    })
  ];
}
