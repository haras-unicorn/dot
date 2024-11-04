{ ... }:

# TODO: configure

{
  home = {
    programs.yazi.enable = true;

    programs.yazi.settings = builtins.fromTOML (builtins.readFile ./settings.toml);
  };
}
