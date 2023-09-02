{ nixos-hardware, modulesPath, ... }:

{
  imports = [
    nixos-hardware.nixosModules.raspberry-pi-4
    # NOTE: doesn't work without this for now
    # it should work with just `nixos-generate`though
    "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"
  ];

  # https://github.com/NixOS/nixpkgs/issues/154163#issuecomment-1008362877  
  nixpkgs.overlays = [
    (final: super: {
      makeModulesClosure = x:
        super.makeModulesClosure (x // { allowMissing = true; });
    })
  ];
}
