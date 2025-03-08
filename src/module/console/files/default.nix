{ ... }:

# TODO: configure

{
  integrate.homeManagerModule.homeManagerModule = {
    programs.yazi.enable = true;

    programs.yazi.settings = builtins.fromTOML (builtins.readFile ./settings.toml);
  };
}
