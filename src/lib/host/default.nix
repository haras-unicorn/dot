{
  lib,
  self,
  inputs,
  root,
  ...
}:

{
  libAttrs.host.mkHost =
    {
      name,
      ip,
      system,
      nixosModule ?
        if self.nixosModules ? "hosts-${name}" then self.nixosModules."hosts-${name}" else { },
      homeModule ? if self.homeModules ? "hosts-${name}" then self.homeModules."hosts-${name}" else { },
      hardware ? lib.path.append root "src/hosts/${name}/hardware.json",
      secrets ? lib.path.append root "src/hosts/${name}/secrets.yaml",
    }:
    let
      nixosModules =
        builtins.attrValues (
          lib.filterAttrs (name: _: !(lib.hasPrefix "host" name) && name != "default") self.nixosModules
        )
        ++ (builtins.attrValues self.lib.host.modules.nixos);
      homeModules =
        builtins.attrValues (
          lib.filterAttrs (name: _: !(lib.hasPrefix "host" name) && name != "default") self.homeModules
        )
        ++ (builtins.attrValues self.lib.host.modules.home);

      pkgs = import inputs.nixpkgs {
        inherit system;
      };

      # NOTE: this is a derivation and not a flake
      patchedNixpkgs = self.lib.nixpkgs.patch pkgs;

      patchedPkgs = import patchedNixpkgs {
        inherit system;
      };
    in
    # NOTE: this is basically how nixosSystem is implemented in nixpkgs
    import "${patchedNixpkgs}/nixos/lib/eval-config.nix" {
      lib = patchedPkgs.lib;
      inherit system;
      modules = nixosModules ++ [
        nixosModule
        (
          { config, ... }:
          {
            nixpkgs.flake.source = patchedNixpkgs;

            dot.host.name = name;
            dot.host.ip = ip;
            dot.host.interface = "dot";
            dot.host.hardware = hardware;
            dot.host.secrets = secrets;

            home-manager.users.${config.dot.host.user}.imports = homeModules ++ [
              homeModule
            ];
          }
        )
      ];
    };
}
