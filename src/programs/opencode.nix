{ unstablePkgs, ... }:

{
  homeManagerModule = {
    programs.opencode.enable = true;
    programs.opencode.package = unstablePkgs.opencode;
  };
}
