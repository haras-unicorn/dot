{ ... }:

# TODO: configure

{
  programs.yazi.enable = true;

  programs.yazi.enableNushellIntegration = true;

  programs.yazi.settings = builtins.fromTOML (builtins.readFile ./settings.toml);
}
