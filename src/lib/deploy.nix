{ self
, nixpkgs
, deploy-rs
, ...
}:

{
  mkDeploy = host: system:
    let
      pkgs = import nixpkgs { inherit system; };
      deployPkgs = import nixpkgs {
        inherit system;
        overlays = [
          deploy-rs.overlay
          (self: super: { deploy-rs = { inherit (pkgs) deploy-rs; lib = super.deploy-rs.lib; }; })
        ];
      };
    in
    {
      hostname = "dummy.com";
      profiles.system = {
        path = deployPkgs.deploy-rs.lib.activate.nixos self.nixosConfigurations."${host}-${system}";
      };
    };
}
