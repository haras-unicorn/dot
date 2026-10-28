{ inputs, ... }:

{
  self.homeModules.certilia.value =
    { pkgs, ... }:
    {
      home.packages = [ inputs.certilia-overlay.packages.${pkgs.stdenv.hostPlatform.system}.default ];
    };
}
