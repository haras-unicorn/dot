{ ... }:

{
  branch.homeManagerModule.homeManagerModule = {
    programs.direnv.enable = true;
    programs.direnv.nix-direnv.enable = true;
  };
}
