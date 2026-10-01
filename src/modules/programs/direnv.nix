{
  machines.homeModules.direnv = { config, ... }: {
    programs.direnv.enable = true;
    programs.direnv.nix-direnv.enable = true;
    programs.direnv.config.whitelist.prefix = [ config.xdg.userDirs.projects ];
  };
}
